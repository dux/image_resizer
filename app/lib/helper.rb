def render_image
  # fix params
  @params[:quality] = (@params[:quality] || @params[:q]).to_i
  @params[:size]  ||= @params[:s]
  @params[:image] ||= @params[:i]

  # define etag and return from cache if possible
  @etag = '"%s"' % Digest::SHA1.hexdigest([@params[:quality], @params[:size], @params[:image]].join('-'))

  if request.env['HTTP_IF_NONE_MATCH'] == @etag
    response.status = 304
    return
  end

  # check for image existance
  return "[image] not defined (can't read query string in production)" unless @params[:image].to_s.length > 5

  # @params[:reload] = true if request.env['HTTP_CACHE_CONTROL'] == 'no-cache'

  img  = ImageResizer.new image: @params[:image],
    size:    @params[:size],
    quality: @params[:quality],
    reload:  !!@params[:reload],
    as_webp: request.env['HTTP_ACCEPT'].to_s.include?('image/webp')

  file = img.resize

  data = File.read file

  response.headers['x-source']            = @params[:image] unless ENV['X_SOURCE'] == 'false'
  response.headers['accept-ranges']       = 'bytes'
  response.headers['etag']                = @etag
  response.headers['cache-control']       = 'public, max-age=10000000, no-transform'
  response.headers['content-type']        = "image/#{img.content_type}"
  response.headers['content-length']      = data.bytesize
  response.headers['content-disposition'] = 'inline'

  data
end

# eyJpbWFnZSI6Imh0dHA6Ly9pLmltZ3VyLmNvbS9rcnVyREdFLmpwZyIsInNpemUiOiIyMjJ4MjIyIn07c62.jpg
def unpack_url url_part
  url_part    = url_part.sub(/\.\w+$/, '')
  base, check = url_part.slice!(0...-4), url_part

  data = Base64.urlsafe_decode64(base)

  if data[0,1] == '{'
    data = JSON.load data
    data = data.inject({}) { |it, (k,v)| it[k.to_sym] = v; it }
  else
    data = { i: data }
    data[:s] = params[:s] || params[:size]
  end

  data[:i] = data[:i].sub(/(\w)/) { $1 == 's' ? 'https://' : 'http://' }

  # if check fails
  unless Digest::SHA1.hexdigest(App::SECRET+base)[0,4] == check
    data[:i] = 'https://i.imgur.com/wgdf507.jpg'
    App.error 'image prefix hash check failed for %s' % data
  end

  data
rescue => e
  App.error e
  data = { i: 'https://i.imgur.com/odix6P2.png', size: '200x200' }
end

def unpack_url url_part
  url_part    = url_part.sub(/\.\w+$/, '')
  base, check = url_part.slice!(0...-2), url_part

  data = Base64.urlsafe_decode64(base)

  if data[0,1] == '{'
    data = JSON.load data
    data = data.inject({}) { |it, (k,v)| it[k.to_sym] = v; it }
  else
    data = { i: data }
  end

  data[:i] = data[:i].sub(/(\w)/) { $1 == 's' ? 'https://' : 'http://' }
  data[:s] ||= params[:s] || params[:size]

  # if check fails
  unless Digest::SHA1.hexdigest(App::SECRET+base)[0,2] == check
    @error = App.error 'Image prefix hash check failed'
  end

  data

rescue => e
  @error = App.error e.message
end

def render_image
  # fix params
  @params[:quality]     = (@params[:quality] || @params[:q]).to_i
  @params[:size]      ||= @params[:s]
  @params[:image]     ||= @params[:i]
  @params[:watermark] ||= @params[:w]

  # define etag and return from cache if possible
  @etag = '"%s"' % Digest::SHA1.hexdigest([@params[:quality], @params[:size], @params[:image]].join('-'))

  if request.env['HTTP_IF_NONE_MATCH'] == @etag
    response.status = 304
    return
  end

  # check for image existance
  return "[image] not defined (can't read query string in production)" unless @params[:image].to_s.length > 5

  # @params[:reload] = true if request.env['HTTP_CACHE_CONTROL'] == 'no-cache'

  img = ImageResizer.new image: @params[:image],
    size:      @params[:size],
    quality:   @params[:quality],
    reload:  !!@params[:reload],
    watermark: @params[:watermark],
    error:     @error,
    as_webp:   request.env['HTTP_ACCEPT'].to_s.include?('image/webp')

  deliver_data img.resize,
    source:       @params[:image],
    etag:         @etag,
    alt:          @params[:e],
    size:         img.size,
    quality:      img.quality,
    error:        img.error,
    content_type: img.content_type
end

def find_ico domain
  data    = []
  threads = []

  domain = 'www.' + domain unless domain[0,4] == 'www.'

  dir = './cache/ico'
  FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  file_location = Pathname.new '%s/%s' % [dir, domain]

  return file_location.to_s if file_location.exist?

  r = RestClient.get("http://#{domain}") rescue nil
  ico = {}

  # find default ico link
  doc = Nokogiri::HTML(r.body)
  doc.xpath('//link[@rel="shortcut icon"]').each do |tag|
    ico['16'] = tag['href']
  end

  # find other ico links
  doc.xpath('//link[@rel="icon"]').each do |tag|
    size = tag['sizes'].to_s.split('x')[1] || '16'
    ico[size] = tag['href']
  end

  # base proto + domain
  base = r.request.url.split('/')
  base = '%s//%s' % [base[0], base[2]]

  # get default 32 ico
  ico = ico['32'] || ico.values.first || "#{base}/favicon.ico"
  ico = ico.sub(/^\/\//, 'https://')

  unless ico.include?('://')
    ico = '/' + ico unless ico[0,1] == '/'
    ico = base + ico
  end

  `curl '#{ico}' -s -o '#{file_location}'`

  if file_location.exist?
    file_location.to_s
  else
    './public/transparent.png'
  end
end

def deliver_data data, opts={}
  response.headers['x-source']            = opts[:source]  if opts[:source] && ENV['X_SOURCE'] != 'false'
  response.headers['x-size']              = opts[:size]    if opts[:size]
  response.headers['x-quality']           = opts[:quality] if opts[:quality]
  response.headers['accept-ranges']       = 'bytes'
  response.headers['etag']                = opts[:etag]

  if opts[:error]
    response.headers['cache-control']     = 'public, max-age=600, no-transform'
    App.error "#{opts[:error]} for image #{opts[:source]}, from #{request.referrer}"
    redirect opts[:alt] if opts[:alt]
  end

  response.headers['cache-control']       = 'public, max-age=10000000, no-transform'
  response.headers['content-type']        = opts[:content_type].to_s.downcase
  response.headers['content-length']      = data.bytesize
  response.headers['content-disposition'] = 'inline'

  response.status = opts[:error] ? 400 : 200

  data
end

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
  unless Digest::SHA1.hexdigest(App.config.secret+base)[0,2] == check
    @error = 'Image prefix hash check failed'
  end

  data

rescue => e
  @error = e.message
end

def render_image
  raise @error if @error

  # fix params
  @params[:quality]     = (@params[:quality] || @params.delete(:q)).to_i
  @params[:size]      ||= @params.delete(:s)
  @params[:image]     ||= @params.delete(:i)
  @params[:watermark] ||= @params.delete(:w)

  if @params[:image].start_with?(App.config.url)
    raise 'Cant referece image on %s' % App.config.url
    # opts = unpack_url @params[:image].split('?').first.split('/')[4]
    # @params[:image]
  end

  # define etag and return from cache if possible
  @etag = '"%s"' % Digest::SHA1.hexdigest([@params[:quality], @params[:size], @params[:image]].join('-'))

  # if request.env['HTTP_IF_NONE_MATCH'] == @etag
  #   response.status = 304
  #   return
  # end

  # check for image existance
  return "[image] not defined (can't read query string in production)" unless @params[:image].to_s.length > 5

  # @params[:reload] = true if request.env['HTTP_CACHE_CONTROL'] == 'no-cache'

  img = ImageResizer.new image: @params[:image],
    size:      @params[:size],
    quality:   @params[:quality],
    reload:  !!@params[:reload],
    watermark: @params[:watermark],
    as_webp:   request.env['HTTP_ACCEPT'].to_s.include?('image/webp')

  deliver_data img.resize,
    source:       @params[:image],
    etag:         @etag,
    alt:          @params[:e],
    size:         img.size,
    quality:      img.quality,
    content_type: img.content_type

rescue => error
  App.log_error error

  image = %{<?xml version="1.0" standalone="no"?>
    <svg width="100%" height="100%">
      <rect width="100%" heigh="100" style="fill:rgb(255,255,255);stroke-width:1;stroke:rgb(150, 150, 150);"></rect>
      <text x="10" y="25" fill="#aaa" font-size="12">Imgage resize server</text>
      <text x="10" y="50" fill="#aaa" font-size="16">#{$!.message}</text>
    </svg>
  }

  deliver_data image, content_type: 'image/svg+xml', etag: @etag
end

def find_ico domain
  data    = []
  threads = []

  domain = 'www.' + domain unless domain[0,4] == 'www.'

  dir = './cache/ico'
  FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  file_location     = Pathname.new '%s/%s' % [dir, domain]
  file_location_ico = Pathname.new '%s.ico' % file_location.to_s

  return file_location.to_s if file_location.exist?
  return file_location_ico.to_s if file_location_ico.exist?

  # find default ico if possible
  ico_cache = "./cache/ico/#{domain}.ico"
  `curl -L http://#{domain}/favicon.ico > #{ico_cache}`
  test = `identify #{ico_cache}`.split(' ')
  return file_location_ico.to_s if test[1] == 'ICO'
  file_location_ico.delete

  # favicon.ico not found, proceed and parse HTML
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
  response.headers['X-Source']            = opts[:source]  if opts[:source] && ENV['X_SOURCE'] != 'false'
  response.headers['X-Size']              = opts[:size]    if opts[:size]
  response.headers['X-Quality']           = opts[:quality] if opts[:quality]
  response.headers['Accept-Ranges']       = 'bytes'
  response.headers['Etag']                = opts[:etag]

  if opts[:error]
    response.headers['Cache-Control']     = 'public, max-age=600, no-transform'
    App.log_error "#{opts[:error]} for image #{opts[:source]}, from #{request.referrer}"
    redirect opts[:alt] if opts[:alt]
  end

  content_type = opts[:content_type].to_s.downcase
  content_type = 'image/%s' % content_type unless content_type.include?('/')

  response.headers['Cache-Control']       = 'public, max-age=10000000, no-transform'
  response.headers['Content-Type']        = content_type
  response.headers['Content-Length']      = data.bytesize
  response.headers['Content-Disposition'] = 'inline'

  response.status = opts[:error] ? 400 : 200

  data
end

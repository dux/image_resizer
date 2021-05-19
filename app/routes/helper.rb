def time_check
  opts = RackImageResizer.decode(params.delete(:time_check))
  time = opts.delete(:time).to_i
  diff = (Time.now.to_i - time).round
  error 'Url check fail' if diff >  10000
  params.merge! opts
end

def rescued
  begin
    yield
  rescue => error
    App.log_error error

    response.headers['X-ErrorMessage'] = error.message
    response.headers['Cache-Control']  = 'public, max-age=600, no-transform'

    if url = @params[:error_url]
      if url == 'blank'
        @image = %{<?xml version="1.0" standalone="no"?>
            <svg width="100%" height="100%" xmlns='http://www.w3.org/2000/svg'>
          </svg>
        }
      else
        retrun redirect(@params[:error_url])
      end
    end

    @image ||= %{<?xml version="1.0" standalone="no"?>
      <svg width="100%" height="100%" xmlns='http://www.w3.org/2000/svg'>
        <rect width="100%" heigh="100" style="fill:rgb(255,255,255);stroke-width:0.1;stroke:rgb(220, 220, 220);"></rect>
        <text x="10" y="25" fill="#aaa" font-size="11" font-family="helvetica">Resize server</text>
        <text x="10" y="50" fill="#aaa" font-size="15" font-family="helvetica">#{error.message}</text>
      </svg>
    }

    deliver_data @image, content_type: 'image/svg+xml', etag: @etag
  end
end

def render_image
  # fix params
  @params[:quality]     = (@params[:quality] || @params.delete(:q)).to_i
  @params[:size]      ||= @params.delete(:s) || @params.delete(:w) || @params.delete(:width)
  @params[:image]     ||= @params.delete(:i)
  @params[:watermark] ||= @params.delete(:w)
  @params[:error_url] ||= @params.delete(:e)

  if App.dev?
    print "\e[H\e[2J\e[3J" # clear osx screen :)
  end

  # check for image existance
  unless @params[:image].to_s.length > 5
    return "[image] not defined (can't read query string in production)"
  end

  # return if image is from local server
  if @params[:image].start_with?(RackImageResizer.config.server)
    raise 'Cant referece image on self (%s)' % RackImageResizer.config.server
  end

  @reload = false

  # full refresh if reload is defined
  if request.env['HTTP_CACHE_CONTROL'] == 'no-cache' && App.dev?
    @reload = true
  elsif @params[:reload]
    if @params[:reload][0,5] == ENV.fetch('RESIZER_SECRET')[0,5]
      @reload = true
    else
      response.headers['X-Error'] = 'BAD REFRESH CODE - RESIZE DISABLED'
    end
  elsif request.env['HTTP_IF_NONE_MATCH'] == @etag
    response.status = 304
    return
  end

  img = ImageResizer.new request: request,
    image:     @params[:image],
    size:      @params[:size],
    quality:   @params[:quality],
    reload:    @reload,
    watermark: @params[:watermark]

  deliver_data img.resize,
    source:       '%s (%s)' % [@params[:image], img.info[1]],
    etag:         @etag,
    size:         '%s (from %s)' % [img.size, img.info[2]],
    quality:      img.quality,
    content_type: img.content_type
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

  Timeout::timeout(15) do
    # find default ico if possible
    ico_cache = "./cache/ico/#{domain}.ico"
    `curl -L http://#{domain}/favicon.ico > #{ico_cache}`
    test = `identify #{ico_cache}`.split(' ')
    return file_location_ico.to_s if test[1] == 'ICO'
    file_location_ico.delete

    # favicon.ico not found, proceed and parse HTML
    r = RestClient.get("http://#{domain}")

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

    raise 'Local file not found' unless file_location.exist?

    file_location.to_s
  end
rescue => error
  App.log_error error
  './public/transparent.png'
end

def deliver_data data, opts={}
  response.headers['X-Source']            = opts[:source]  if opts[:source] && ENV['X_SOURCE'] != 'false'
  response.headers['X-Size']              = opts[:size]    if opts[:size]
  response.headers['X-Quality']           = opts[:quality] if opts[:quality]
  response.headers['X-HumanSize']         = App.filesize data.bytesize

  response.headers['Accept-Ranges']       = 'bytes'
  response.headers['Etag']                = opts[:etag]

  content_type = opts[:content_type].to_s.downcase
  content_type = 'image/%s' % content_type unless content_type.include?('/')

  response.headers['Cache-Control']       = 'public, max-age=10000000, no-transform'
  response.headers['Content-Type']        = content_type
  response.headers['Content-Length']      = data.bytesize
  response.headers['Content-Disposition'] = 'inline'

  response.status = 200

  ap Hash[response.headers.sort] if App.dev?

  data
end

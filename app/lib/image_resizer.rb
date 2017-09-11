require 'logger'

class ImageResizer

  ICON     = File.read('./public/favicon.ico')
  LOG_FILE = './log/%s.log' % ENV['RACK_ENV']
  LOGGER   = Logger.new(LOG_FILE, 'weekly')
  LOGGER.datetime_format = '%F %R'

  class << self
    def call env
      app = new env
      app.router
      app.deliver
    end

    def log text
      LOGGER.info text
    end
  end

  ###

  def initialize env
    @request  = Rack::Request.new env
    @response = Rack::Response.new
  end

  def from_http_cache
    @md5 = Digest::MD5.hexdigest @path[1]

    if @request.env['HTTP_IF_NONE_MATCH'] == @md5 && !@request.params[:reload]
      @response.status = 304
      @response.write 'not-modified'
      return true
    else
      false
    end
  end

  def unpack_path
    # /r/{some-name}/hash.jpg
    # /r/hash~{some-name}.jpg # tilde
    data = @path[1].split('/').last.split('~').first
    data = data.sub(/\.\w{3,4}$/,'')
    ImageResizerEncoder.unpack(data)
  end

  def router
    @path = @request.path.split('/').drop(1)

    @params = if @path[0] == 'r' && @path[1]
      # if we have hashed paramteres
      return if from_http_cache

      # recieved packed string
      unpack_path
    elsif is_local
      @request.params.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
    end

    # routing
    data = case @path[0].to_s
      when 'r'
        get_resize
      when 'pack'
        get_pack if is_local
      when 'log'
        File.read LOG_FILE
      when ''
        File.read('./public/%s.html' % ENV.fetch('RACK_ENV'))
      when 'favicon.ico'
        @response.headers["Content-Length"] = ICON.length
        @response.headers["Content-Type"]   = "image/vnd.microsoft.icon"
        ICON
      else
        file = './public%s' % @request.path
        if File.exists?(file)
          @response.headers["Content-Type"] = 'text/%s' % file.index('.html') ? 'html' : 'plain'
          File.read(file)
        else
          'HTTP 404 - not found'
          @response.status = 404
        end
    end

    @response.write data
  rescue
    # raise $! if is_local

    msg = '%s (%s)' % [$!.message, $!.class]
    self.class.log 'ERROR: %s - %s' % [msg, @request.url]

    @response.write msg
    @response.status = 500
  end

  def deliver
    return [400, {}, ['Error: No response body']] unless @response.body[0]
    @response.status ||= 200
    @response.finish
  end

  def is_local
    # ['127.0.0.1','0.0.0.0'].index(@request.ip)
    ENV.fetch('RACK_ENV') == 'development'
  end

  ### ROTUES

  def get_pack
    url = "#{@request.env['rack.url_scheme']}://#{@request.env['HTTP_HOST']}/r/#{ImageResizerEncoder.pack(@params)}.jpg"

    return %[<html><head></head><body><h3>On server</h3><pre>ImageResizerEncoder.url(#{JSON.pretty_generate(@params)})</pre>
      <hr />
      <h3>Will output</h3>
      <a href="#{url}">#{url}</a></body></html>]
  end

  # image: URL to image
  # width: width of image
  # height: height of image
  # crop: crop area of image
  def get_resize
    # we need to have at least one sizeing attribute

    image = @params[:image]
    return '[image] not defined' unless image.to_s.length > 1

    resize_width, resize_height = @params[:size].to_s.split('x').map(&:to_i)
    resize_width  ||= 0
    resize_height ||= 0

    return "Width and height from :size are 0" unless resize_width > 10 || resize_height > 10
    return 'Image to large' if resize_width > 1500 || resize_height > 1500

    @params[:q] = @params[:q].to_i
    @params[:q] = 85 if @params[:q] < 10

    reload = false
    reload = true if @params[:reload]
    # reload = true if request.env['HTTP_CACHE_CONTROL'] == 'no-cache'

    img = ImageResizerImage.new image: image, quality: @params[:q], reload: reload, is_local: is_local
    ext = img.ext

    file = if resize_width > 0 && resize_height > 0
      gravity = @params[:gravity].to_s.downcase
      gravity = 'North' if gravity.length == 0
      img.crop(@params[:size], gravity)
    elsif resize_width > 0
      img.resize_width(resize_width)
    elsif resize_height > 0
      img.resize_height(resize_height)
    else
      raise '?'
    end

    data = File.read file

    @md5 ||= Digest::MD5.hexdigest data

    @response.headers['ETag']                = @md5
    @response.headers['Content-Type']        = "image/#{ext}"
    @response.headers['Cache-Control']       = 'public, max-age=10000000, no-transform'
    @response.headers['Connection']          = 'keep-alive'
    @response.headers['Content-Disposition'] = %[inline; filename="#{@md5}.#{ext}"]
    @response.headers['Connection']          = 'keep-alive'

    data
  end

end

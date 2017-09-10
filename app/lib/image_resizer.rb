class ImageResizer

  ICON = File.read('./public/favicon.ico')

  class << self
    def call env
      app = new env
      data = app.router
      app.deliver
    end
  end

  ###

  def initialize env
    @request  = Rack::Request.new env
    @response = Rack::Response.new
  end

  def error msg
    @has_error = true
    @response.body   = msg
    @response.status = 500
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
    ap data
    opts = ImageResizerEncoder.unpack(data)
    opts rescue error("jwt error: #{$!.message}")
  end

  def router
    @path = @request.path.split('/').drop(1)

    @params = if @path[1]
      # if we have hashed paramteres
      return if from_http_cache

      # recieved packed string
      unpack_path
    elsif is_local
      @request.params.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
    end

    # routing
    data = case @path[0].to_s[0, 1]
      when 'f'
        @response.headers["Content-Length"] = ICON.length
        @response.headers["Content-Type"]   = "image/vnd.microsoft.icon"
        ICON
      when 'r'
        get_resize
      when 'p'
        get_pack if is_local
      else
        get_root
    end

    @response.write data unless @has_error
  end

  def deliver
    return [400, {}, ['Error: No response body']] unless @response.body[0]
    @response.status ||= 200
    @response.finish
  end

  def is_local
    ['127.0.0.1','0.0.0.0'].index(@request.ip)
  end

  ### ROTUES

  def get_root
    File.read('./public/index.html')
  end

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
    # raise StandardError, @params[:width]
    return "Missing :width, :height or :crop parameter" unless @params[:width] || @params[:height] || @params[:crop]

    image = @params[:image]
    return '[image] not defined' unless image.to_s.length > 1

    resize_width  = @params[:width].to_i
    resize_height = @params[:height].to_i
    crop_size     = @params[:crop]

    @params[:q] = @params[:q].to_i
    @params[:q] = 85 if @params[:q] < 10

    reload = false
    reload = true if @params[:reload]
    # reload = true if request.env['HTTP_CACHE_CONTROL'] == 'no-cache'

    img = ImageResizerImage.new image: image, quality: @params[:q], reload: reload
    ext = img.ext

    if resize_width > 0
      return 'Image to large' if resize_width > 1500
      file = img.resize_width(resize_width)
    elsif resize_height > 0
      return 'Image to large' if resize_height > 1500
      file = img.resize_height(resize_height)
    else
      gravity = params[:gravity].to_s.downcase
      gravity = 'North' if gravity.length == 0
      file = img.crop(crop_size, gravity)
    end

    data = File.read file

    @md5 ||= Digest::MD5.hexdigest data

    @response.headers['Content-Type'] = "image/#{ext}"
    @response.headers['Cache-Control'] = 'public, max-age=10000000, no-transform'
    @response.headers['ETag'] = @md5
    @response.headers['Connection'] = 'keep-alive'
    @response.headers['Content-Disposition'] = %[inline; filename="#{@md5}.#{ext}"]
    @response.headers['Connection'] = 'keep-alive'

    data
  end

end

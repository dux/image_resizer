class ImageResizer

  attr_accessor :request, :response, :params

  class << self
    def call(env)
      app = new(env)
      app.router
      app.deliver
    end
  end

  ###

  def initialize(env)
    @request  = Rack::Request.new(env)
    @response = Rack::Response.new
  end

  def router
    root = @request.path.split('/')[1]
    return get(:root) unless root

    @params = @request.params.keys.inject({}){|h,k| h[k.to_sym] = @request.params[k]; h }
    @md5 = Digest::MD5.hexdigest @params.to_json

    if request.env['HTTP_IF_NONE_MATCH'] == @md5 && !@request.params[:reload]
      response.status = 304
      response.write 'not-modified'
      return
    end

    root = 'resize' if  root[0, 1] == 'r'

    get(root)
  end

  def deliver
    return [400, {}, ['Error: No response body']] unless @response.body[0]
    @response.status ||= 200
    @response.finish
  end

  def is_local
    ['127.0.0.1','0.0.0.0'].index(request.ip)
  end

  def get(what)
    method = "get_#{what}"
    if respond_to?(method)
      @response.write send(method)
    else
      @response.status = 400
      @response.write "Request :#{what} is not supported"
    end
  end

  ### ROTUES

  def get_root
    File.read('./app/views/index.html')
  end

  def get_pack
    opts = [:width, :height, :crop, :image].inject({}) { |h, k| h[k] = params[k] if params[k]; h }
    secret = params[:secret] || '-'

    url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/r/#{ImageResizerEncoder.pack(opts, secret)}.jpg"

    return %[<html><head></head><body><h3>On server</h3><pre>ResizePacker.url(#{JSON.pretty_generate(opts)})</pre>
      <hr />
      <h3>Will output</h3>
      <a href="#{url}">#{url}</a></body></html>]
  end

  # image: URL to image
  # width: width of image
  # height: height of image
  # crop: crop area of image
  # unsafe: allow width, height and crop to be defined in params
  def get_resize
    opts = {}

    # recieved packed string
    # /r/{some-name}/hash.jpg
    # /r/hash--{some-name}.jpg # note double dash
    if data = request.path.split('/').last.split('--').first
      data.sub!(/\.\w{3,4}$/,'')
      opts = ImageResizerEncoder.unpack(data) rescue Proc.new { return "jwt error: #{$!.message}" }.call
    end

    # if :unsafe recieved in packed string, allow unsafe image resize
    if opts[:unsafe] == 'true' || is_local
      for key in [:width, :height, :crop]
        opts[key] = params[key] if params[key]
      end
    end

    opts[:image] ||= params[:image] if is_local

    # we need to have at least one sizeing attribute
    # raise StandardError, opts[:width]
    return "Missing :width, :height or :crop parameter" unless opts[:width] || opts[:height] || opts[:crop]

    image = opts[:image]
    return '[image] not defined' unless image.to_s.length > 1

    resize_width  = opts[:width].to_i
    resize_height = opts[:height].to_i
    crop_size     = opts[:crop]

    opts[:q] ||= 85

    img = ImageResizerImage.new(image, opts[:q].to_i, params[:reload] == 'true')
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

    unless File.exist?(file)
      data = File.read(img.original)
      response.headers['Content-Type'] = "text/html" if data.index('</body>')
      if request.env['HTTP_CACHE_CONTROL'] == 'no-cache' # && HTTP_REFERER EMPTY
        File.unlink(img.original)
        return 'Bad cache deleted, refresh again.'
      end

      return data
    end

    data = File.read file

    response.headers['Content-Type'] = "image/#{ext}"
    response.headers['Cache-Control'] = 'public, max-age=10000000, no-transform'
    response.headers['ETag'] = @md5
    response.headers['Connection'] = 'keep-alive'
    response.headers['Content-Disposition'] = %[inline; filename="#{@md5}.#{ext}"]
    response.headers['Connection'] = 'keep-alive'

    data
  end

end

def render_image
  @params[:q]       = (@params[:quality] || @params[:q]).to_i
  @params[:width]   = (@params[:width]   || @params[:h]).to_i
  @params[:height]  = (@params[:height]  || @params[:h]).to_i
  @params[:size]  ||=  @params[:s]
  @params[:image] ||=  @params[:i]

  image = @params[:image]
  return "[image] not defined (can't read query string in production)" unless image.to_s.length > 1

  resize_width, resize_height = @params[:size].to_s.split('x').map(&:to_i)
  resize_width  ||= @params[:width].to_i
  resize_height ||= @params[:height].to_i

  return "Width and height from :size are 0" unless resize_width > 10 || resize_height > 10
  return 'Image to large' if resize_width > 1500 || resize_height > 1500

  @params[:q] = 85 if @params[:q] < 10

  reload = false
  reload = true if @params[:reload]
  # reload = true if request.env['HTTP_CACHE_CONTROL'] == 'no-cache'

  img = ImageResizer.new image: image, quality: @params[:q], reload: reload, is_local: App.is_local?, as_webp: request.env['HTTP_ACCEPT'].to_s.include?('image/webp')

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

  @etag = '"%s"' % Digest::MD5.hexdigest(data)

  if request.env['HTTP_IF_NONE_MATCH'] == @etag
    response.status = 304
    return
  end

  response.headers['x-source']            = image unless ENV['X_SOURCE'] == 'false'
  response.headers['accept-ranges']       = 'bytes'
  response.headers['etag']                = @etag
  response.headers['cache-control']       = 'public, max-age=10000000, no-transform'
  response.headers['content-type']        = "image/#{img.content_type}"
  response.headers['content-length']      = data.bytesize
  response.headers['content-disposition'] = 'inline'

  data
end

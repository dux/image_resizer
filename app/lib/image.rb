class Image
  attr_reader :ext, :original, :resized

  def initialize(image, quality=80)
    @image = image
    @ext = image.split('.').reverse[0].to_s
    @ext = 'jpg' unless @ext.length > 2 && @ext.length < 5
    @ext = @ext.downcase
    @quality = quality < 10 ? 80 : quality
    @original = "#{ROOT}/cache/originals/#{md5(@image)}.#{@ext}"
  end

  def download(target=nil)
    `curl '#{@image}' --create-dirs -s -o '#{@original}'` unless File.exists?(@original)

    if dir = target.dup
      dir.gsub!(/\/[^\/]+$/,'')
      Dir.mkdir dir unless Dir.exists?(dir)
    end

    @original
  end

  def resize_width(size)
    resized = "#{ROOT}/cache/resized/w_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"

    unless File.exists?(resized)
      download resized
      `convert '#{@original}' -quality #{@quality} -resize #{size}x '#{resized}'`
    end
    resized
  end

  def resize_height(size)
    resized = "#{ROOT}/cache/resized/h_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"

    unless File.exists?(resized)
      download resized
      # raise StandardError, "convert '#{@original}' -quality #{@quality} -resize x#{size} '#{resized}'"
      `convert '#{@original}' -quality #{@quality} -resize x#{size} '#{resized}'`
    end
    resized
  end

  def crop(size, gravity)
    width, height = size.to_s.downcase.split('x')
    height ||= width
    raise 'Image to large' if width.to_i > 1500 || height.to_i > 1500
    cropped = "#{ROOT}/cache/croped/#{width}x#{height}-q#{@quality}-#{md5(@image)}.#{@ext}"
    unless File.exists?(cropped)
      download cropped
      `convert #{@original} -quality #{@quality} -resize #{width}x#{height}^ -gravity #{gravity} -background black -extent #{width}x#{height} #{cropped}`
    end
    cropped
  end

end
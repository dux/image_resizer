class ImageResizerImage
  attr_reader :ext, :original, :resized

  def initialize(image, quality=80)
    @image = image
    @ext = image.split('.').reverse[0].to_s
    @ext = 'jpg' unless @ext.length > 2 && @ext.length < 5
    @ext = 'jpg' if @ext == 'jpeg'
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

  def convert_base
    # remove alpha for jpegs and keep for png-s
    "convert '#{@original}' -alpha #{@ext == 'jpg' ? 'remove -background white' : 'on'} -strip -quality #{@quality}"
  end

  def resize_width(size)
    resized = "#{ROOT}/cache/resized/w_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"

    unless File.exists?(resized)
      download resized
      `#{convert_base} -resize #{size}x '#{resized}'`
    end
    resized
  end

  def resize_height(size)
    resized = "#{ROOT}/cache/resized/h_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"

    unless File.exists?(resized)
      download resized
      # raise StandardError, "convert '#{@original}' -quality #{@quality} -resize x#{size} '#{resized}'"
      `#{convert_base} -resize x#{size} '#{resized}'`
    end
    resized
  end

  def crop(size, gravity)
    size.gsub!(' ','+')
    width, height, x_offset, y_offset = size.to_s.downcase.split(/[x\+]/)
    height ||= width
    raise 'Image to large' if width.to_i > 1500 || height.to_i > 1500
    cropped = "#{ROOT}/cache/croped/#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"
    unless File.exists?(cropped)
      download cropped

      if y_offset
        # crop with offset, without resize
        `#{convert_base} -crop #{width}x#{height}+#{x_offset}+#{y_offset} -gravity #{gravity} -extent #{width}x#{height} #{cropped}`
      else
        # regular resize crop
        `#{convert_base} -resize #{width}x#{height}^ -gravity #{gravity} -extent #{width}x#{height} #{cropped}`
      end
    end
    cropped
  end

end
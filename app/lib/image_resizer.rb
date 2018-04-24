# main class that handles image resizing

class ImageResizer
  attr_reader :ext, :image, :original, :resized

  def initialize image:, quality:80, reload:nil, is_local: false
    ext = image.split('.').reverse[0].to_s
    ext = 'jpg' unless ext.length > 2 && ext.length < 5
    ext = 'jpeg' if ext == 'jpg'

    @image        = image
    @ext          = ext.downcase
    @quality      = quality < 10 || quality > 100 ? 80 : quality
    @src_in_cache = "#{App.root}/cache/originals/#{md5(@image)}.#{@ext}"
    @reload       = reload

    File.unlink(@src_in_cache) if @reload && File.exist?(@src_in_cache)
  end

  def md5 data
    ret = Digest::MD5.hexdigest data
    ret[2,0] = ''
    ret
  end

  def run what
    # puts what
    system "#{what} 2>&1"
  end

  def log text
    App.log text
  end

  def download target=nil
    unless File.exists?(@src_in_cache)
      run "curl '#{@image}' --create-dirs -s -o '#{@src_in_cache}'"
      log 'DOWNLOAD %s (%d kb)' % [@image, File.stat(@src_in_cache).size/1024]
    end

    if dir = target.dup
      dir.gsub!(/\/[^\/]+$/,'')
      Dir.mkdir dir unless Dir.exists?(dir)
    end

    @src_in_cache
  end

  def convert_base
    # remove alpha for jpegs and keep for png-s
    "convert '#{@src_in_cache}' -alpha #{@ext == 'jpg' ? 'remove -background white' : 'on'} -strip -quality #{@quality}"
  end

  def resize_do img_path
    resized = '%s/cache/%s' % [App.root, img_path]
    File.unlink(resized) if @reload && File.exist?(resized)

    unless File.exists? resized
      download resized
      yield resized
    end

    resized
  end

  def resize_width size
    resize_do "resized/w_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}" do |resized|
      log 'WIDTH of %s to %d' % [@image, size]
      run "#{convert_base} -resize #{size}x '#{resized}'"
    end
  end

  def resize_height size
    resize_do "resized/h_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}" do |resized|
      log 'HEIGHT of %s to %d' % [@image, size]
      run "#{convert_base} -resize x#{size} '#{resized}'"
    end
  end

  def crop size, gravity
    size.gsub!(' ','+')
    width, height, x_offset, y_offset = size.to_s.downcase.split(/[x\+]/)
    height ||= width
    raise 'Image to large' if width.to_i > 1500 || height.to_i > 1500

    resize_do "croped/#{size}-q#{@quality}-#{md5(@image)}.#{@ext}" do |cropped|
      if y_offset
        # crop with offset, without resize
        dimension = "#{width}x#{height}+#{x_offset}+#{y_offset}"
        log 'CROP %s to %s' % [@image, dimension]
        run "#{convert_base} -crop #{dimension} -gravity #{gravity} -extent #{width}x#{height} #{cropped}"
      else
        # regular resize crop
        dimension = "#{width}x#{height}^"
        log 'CROP %s to %s' % [@image, dimension]
        run "#{convert_base} -resize #{dimension} -gravity #{gravity} -extent #{width}x#{height} #{cropped}"
      end
    end
  end

end
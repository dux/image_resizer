# main class that handles image resizing

class ImageResizer
  attr_reader :ext, :image, :original, :resized

  def initialize image:, quality:80, reload:nil, is_local:false, as_webp: false
    ext = image.split('.').reverse[0].to_s
    ext = 'jpeg' unless ext.length > 2 && ext.length < 5
    ext = 'jpeg' if ext == 'jpg'

    @image        = image
    @ext          = ext.downcase
    @quality      = quality < 10 || quality > 100 ? 80 : quality
    @src_in_cache = "#{App.root}/cache/originals/#{md5(@image)}.#{@ext}"
    @reload       = reload
    @as_webp      = as_webp

    # gif has errors and png has no
    @as_webp = false unless ext == 'jpeg'

    File.unlink(@src_in_cache) if @reload && File.exist?(@src_in_cache)
  end

  def md5 data
    ret = Digest::MD5.hexdigest data
    ret[2,0] = ''
    ret
  end

  def run what
    App.log what
    # puts what
    system "#{what} 2>&1"
  end

  def log text
    App.log.info text
  end

  def content_type
    case @ext
      when 'svg'
        'svg+xml'
      else
        @ext
    end
  end

  def download
    unless File.exists?(@src_in_cache)
      run "curl -L '#{@image}' --create-dirs -s -o '#{@src_in_cache}'"

      if File.exists?(@src_in_cache)
        log 'DOWNLOAD %s (%d kb)' % [@image, File.stat(@src_in_cache).size/1024]
      else
        log 'ERROR %s (cant download)' % @image
        return @src_in_cache = './public/error.png'
      end
    end

    @src_in_cache
  end

  def convert_base width=nil
    width = width.to_i

    opts  = []
    opts.push "-auto-orient"
    opts.push "-alpha #{@ext == 'jpg' ? 'remove -background white' : 'on'}"
    opts.push "-strip"
    opts.push "-quality #{@quality}"
    opts.push '-unsharp 4x2+1+0' if @ext == 'jpeg' && width > 0 && width < 101
    opts.push '-interlace Plane'

    'convert "%s" %s' % [@src_in_cache, opts.join(' ')]
  end

  def optimize
    case @ext
      when 'png'
        run "pngquant -f --output #{@target} --strip #{@target}" unless @as_webp
      # not needed with imagemagic?
      # when 'jpeg'
      #   run "jpegoptim #{@target}"
    end
  end

  def resize_do img_path
    @target = '%s/cache/%s' % [App.root, img_path]

    File.unlink(@target) if @reload && File.exist?(@target)

    return @src_in_cache if @ext == 'svg'

    unless File.exists? @target
      download
      yield
      optimize
    end

    unless File.exists? @target
      File.unlink(@src_in_cache)
      return './public/error.png'
    end

    if @as_webp
      @ext = 'webp'
      new_target = @target.sub(/\.\w+$/, '.webp') if @as_webp
      WebP.encode(@target, new_target, quality: 90)
      new_target
    else
      @target
    end
  end

  def resize_width size
    resize_do "resized/w_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}" do
      log 'WIDTH of %s to %d' % [@image, size]
      run "#{convert_base(size)} -resize #{size}x '#{@target}'"
    end
  end

  def resize_height size
    resize_do "resized/h_#{size}-q#{@quality}-#{md5(@image)}.#{@ext}" do
      log 'HEIGHT of %s to %d' % [@image, size]
      run "#{convert_base} -resize x#{size} '#{@target}'"
    end
  end

  def crop size, gravity
    size.gsub!(' ','+')
    width, height, x_offset, y_offset = size.to_s.downcase.split(/[x\+]/)
    height ||= width
    raise 'Image to large' if width.to_i > 1500 || height.to_i > 1500

    resize_do "croped/#{size}-q#{@quality}-#{md5(@image)}.#{@ext}" do
      if y_offset
        # crop with offset, without resize
        dimension = "#{width}x#{height}+#{x_offset}+#{y_offset}"
        log 'CROP %s to %s' % [@image, dimension]
        run "#{convert_base(width)} -crop #{dimension} -gravity #{gravity} -extent #{width}x#{height} '#{@target}'"
      else
        # regular resize crop
        dimension = "#{width}x#{height}^"
        log 'CROP %s to %s' % [@image, dimension]
        run "#{convert_base(width)} -resize #{dimension} -gravity #{gravity} -extent #{width}x#{height} #{@target}"
      end
    end
  end
end
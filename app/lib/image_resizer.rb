# main class that handles image resizing

class ImageResizer
  attr_reader :ext, :image, :original, :resized

  def initialize image:, size:, quality: nil, reload: false, as_webp: false
    ext = image.split('.').reverse[0].to_s
    ext = 'jpeg' unless ext.length > 2 && ext.length < 5
    ext = 'jpeg' if ext == 'jpg'

    @image        = image
    @ext          = ext.downcase
    @quality      = quality < 10 || quality > 100 ? 90 : quality
    @src_in_cache = "#{App.root}/cache/o/#{sha1(@image)}.#{@ext}"
    @reload       = reload
    @as_webp      = as_webp
    @size         = size.to_s

    # check max width and height
    max_size = (ENV.fetch('MAX_IMAGE_SIZE') { 1600 }).to_i

    for el in @size.split('x').map { |it| it.gsub(/[^\d]/, '').to_i }
      raise ArgumentError.new('Image to large, max 1600') if el && el > max_size
    end

    # gif has errors and png has no
    @as_webp = false unless ext == 'jpeg'

    File.unlink(@src_in_cache) if @reload && File.exist?(@src_in_cache)

    App.log 'RESIZE "%s" TO "%s"' % [@image, @size]
  end

  def sha1 data
    Digest::SHA1.hexdigest data
  end

  def run what
    App.dev_log what
    # puts what
    system "#{what} 2>&1"
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
        App.log 'DOWNLOAD %s (%d kb)' % [@image, File.stat(@src_in_cache).size/1024]
      else
        App.log 'ERROR %s (cant download)' % @image
        return @src_in_cache = './public/error.png'
      end
    end

    @src_in_cache
  end

  def convert_base
    size    = @size

    do_unsharp =
      if size.include?('u')
        size = size.sub('u','')
        true
      else
        false
      end

    size   += 'x' if size =~ /^\d+$/
    size   += 'x'+size.sub('^','') if size.include?('^') && !size.include?('x')

    opts = []
    opts.push '-auto-orient'
    opts.push '-strip'
    opts.push "-quality #{@quality}"
    opts.push '-resize %s' % size
    opts.push '-unsharp %s' % ENV.fetch('UNSHARP_MASK') { '1x1+1+0' } if do_unsharp && @ext == 'jpeg'
    opts.push '-interlace Plane'

    if size.include?('^')
      opts.push '-gravity North'
      opts.push '-extent %s' % size.sub('^','')
    end

    run 'convert "%s" %s %s' % [@src_in_cache, opts.join(' '), @target]
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

  def resize
    download

    return @src_in_cache if @ext == 'svg'

    @target = [App.root, "r/s#{@size}/q#{@quality}-#{sha1(@image)}.#{@ext}"].join('/cache/')
    target_dir = @target.sub(%r{/[^/]+$}, '')

    File.unlink(@target) if @reload && File.exist?(@target)
    FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

    unless File.exists? @target
      convert_base
      optimize
    end

    unless File.exists? @target
      File.unlink(@src_in_cache)
      return './public/error.png'
    end

    if @as_webp
      @ext = 'webp'
      new_target = @target.sub(/\.\w+$/, '.webp') if @as_webp
      WebP.encode(@target, new_target, quality: @quality)
      new_target
    else
      @target
    end
  end
end
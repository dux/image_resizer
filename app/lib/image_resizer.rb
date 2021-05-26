# main class that handles image resizing

class ImageResizer
  @@opts ||= Struct.new 'ImageResizerOpts', :ext, :image, :original, :resized, :cache_path, :quality, :size, :reload, :as_webp, :request, :watermark

  def initialize image:, size:, quality: nil, watermark: nil, reload: false, as_webp: false, request: nil
    ext = image.split('?').first.split('.').last.to_s.downcase
    ext = 'jpeg' unless ext.length > 2 && ext.length < 5
    ext = 'jpeg' if ext == 'jpg'

    @opt = @@opts.new

    @opt.image     = image
    @opt.ext       = ext.downcase
    @opt.quality   = quality < 10 || quality > 100 ? App.config.quality : quality
    @opt.original  = "#{App.config.root}/cache/o/#{sha1(@opt.image)}.#{@opt.ext}"
    @opt.reload    = reload
    @opt.as_webp   = as_webp
    @opt.request   = request
    @opt.size      = size.to_s.gsub(/['"]/, '')
    @opt.watermark = watermark
    @opt.size      = nil if @opt.size == ''

    # check max width and height
    max_size = (ENV.fetch('MAX_IMAGE_SIZE') { 2000 }).to_i

    if @opt.size
      for el in @opt.size.split('x').map { |it| it.gsub(/[^\d]/, '').to_i }
        raise ArgumentError.new('Image to large, max 1600') if el && el > max_size
      end
    end

    # gif has errors and png has no
    @opt.as_webp = request && request.env['HTTP_ACCEPT'].to_s.include?('/webp')
    @opt.as_webp = false unless ['jpeg', 'png', 'webp'].include?(ext)

    File.unlink(@opt.original) if @opt.reload && File.exist?(@opt.original)
  end

  def resize
    download

    return File.read(@opt.original) if @opt.ext == 'svg'

    if @opt.size
      raise 'Source image not found' unless info[2]

      # do not apply resize if new width or height is less then original
      size = @opt.size.split('x')
      size[1] ||= 0
      size = size
        .push(info[2].split('x'))
        .flatten
        .map(&:to_i)


      @opt.size = info[2] if size[0] > size[2] || size[1] > size[3]
    else
      # if size not provided, only apply quality filter
      @opt.size = info[2]
    end

    # if original is webp but it is not supporter, it has to be converted
    if @opt.ext == 'webp' && !@opt.as_webp
      @opt.ext = 'jpeg'
    end

    @opt.resized = [App.config.root, "r/s#{@opt.size.sub('^', 'c').gsub(/[^\w]/, '')}/q#{@opt.as_webp ? 95 : @opt.quality}-#{sha1(@opt.image+@opt.watermark.to_s)}.#{@opt.ext}"].join('/cache/')
    target_dir = @opt.resized.sub(%r{/[^/]+$}, '')

    FileUtils.mkdir_p target_dir unless Dir.exist?(target_dir)

    if @opt.reload && File.exist?(@opt.resized)
      File.unlink(@opt.resized)
    end

    unless File.exists?(@opt.resized)
      text  = 'RESIZE "%s" TO "%s"' % [@opt.image, @opt.size]
      text += ' (%s | %s)' % [@opt.request.ip || '-', @opt.request.env['HTTP_REFERER'] || '-'] if @opt.request
      App.log text

      convert_base
      apply_watermark
      optimize
    end

    unless File.exists? @opt.resized
      File.unlink(@opt.original)
      raise 'Resize failed'
    end

    @opt.cache_path =
    if @opt.as_webp && false # disabled because grayed out images
      @opt.ext = 'webp'
      new_target = @opt.resized.sub(/\.\w+$/, '.webp')

      if @opt.reload || !File.exist?(new_target)
        run "cwebp -quiet -q #{@opt.quality.to_i} #{@opt.resized} -o #{new_target}"
      end

      new_target
    else
      @opt.resized
    end

    File.read @opt.cache_path
  rescue => e
    error = e.message
    error = 'Resize error' if error.include?('No such file')
    raise error
  end

  def content_type
    case @opt.ext
      when 'svg'
        'svg+xml'
      else
        @opt.ext
    end
  end

  def info
    @info ||= `identify #{@opt.original}`.split(' ')
  end

  def size
    @opt.size
  end

  def quality
    @opt.quality
  end

  def resized
    @opt.resized
  end

  private

  def sha1 data
    Digest::SHA1.hexdigest data
  end

  def run what
    App.run what
  end

  def download
    unless File.exists?(@opt.original)
      run "curl --max-time 10 -L '#{@opt.image}' --create-dirs -s -o '#{@opt.original}'"

      if File.exists?(@opt.original)
        App.log 'DOWNLOAD %s (%d kb)' % [@opt.image, File.stat(@opt.original).size/1024]
      else
        raise "Can't download source from %s" % @opt.image
      end
    end

    @opt.ext = info[1].downcase if info[2].to_s.include?('x')
    @opt.ext = 'webp' if @opt.ext == 'pam'

    raise 'Source error' if info[2] == '0x0'

    @opt.original
  end

  def convert_base
    size = @opt.size

    do_unsharp =
      if size.include?('u')
        size = size.sub('u','')
        true
      else
        false
      end

    size  = size.sub('c','^')
    size += 'x' if size =~ /^\d+$/
    size += 'x'+size.sub('^','') if size.include?('^') && !size.include?('x')

    opts = []
    opts.push '-synchronize'
    opts.push '-auto-orient'
    opts.push '-strip'
    opts.push '-quality 95'
    opts.push '-resize %s' % size
    opts.push '-unsharp %s' % ENV.fetch('UNSHARP_MASK') { '1x1+1+0' } if do_unsharp && @opt.ext == 'jpeg'
    opts.push '-interlace Plane'
    opts.push '-background none' if @opt.ext == 'png'

    if size.include?('^')
      opts.push '-gravity North'
      opts.push '-extent %s' % size.sub('^','')
    end

    # I have wired resize bug
    # https://legacy.imagemagick.org/discourse-server/viewtopic.php?t=32185
    # tried to add synchronize and sleep to fix
    run 'convert "%s" %s %s' % [@opt.original, opts.join(' '), @opt.resized]
  end

  def optimize
    case @opt.ext
      when 'png'
        run "pngquant -f --output #{@opt.resized} #{@opt.resized}"
    end
  end

  def apply_watermark
    return unless @opt.watermark

    image, gravity, percent = @opt.watermark.split(':')
    gravity ||= 'SouthEast' # None, Center, East, Forget, NorthEast, North, NorthWest, SouthEast, South, SouthWest, West
    percent ||= 30

    run "composite -watermark 30% -gravity #{gravity} ./public/#{image}.png #{@opt.resized} #{@opt.resized}"
  end
end

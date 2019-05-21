# main class that handles image resizing

class ImageResizer
  attr_reader :ext, :image, :original, :resized, :cache_path, :quality, :size

  def initialize image:, size:, error: nil, quality: nil, watermark: nil, reload: false, as_webp: false
    ext = image.split('?').first.split('.').reverse[0].to_s.downcase
    ext = 'jpeg' unless ext.length > 2 && ext.length < 5
    ext = 'jpeg' if ext == 'jpg'

    @image     = image
    @ext       = ext.downcase
    @quality   = quality < 10 || quality > 100 ? App::QUALITY : quality
    @original  = "#{App.root}/cache/o/#{sha1(@image)}.#{@ext}"
    @reload    = reload
    @as_webp   = as_webp
    @size      = size.to_s.gsub(/['"]/, '')
    @error     = error
    @watermark = watermark
    @size      = nil if @size == ''

    # check max width and height
    max_size = (ENV.fetch('MAX_IMAGE_SIZE') { 1600 }).to_i

    if @size
      for el in @size.split('x').map { |it| it.gsub(/[^\d]/, '').to_i }
        raise ArgumentError.new('Image to large, max 1600') if el && el > max_size
      end
    end

    # gif has errors and png has no
    @as_webp = false unless ext == 'jpeg'

    File.unlink(@original) if @reload && File.exist?(@original)

    App.log 'RESIZE "%s" TO "%s"' % [@image, @size]
  end

  def sha1 data
    Digest::SHA1.hexdigest data
  end

  def run what
    App.log 'RUN: %s' % what
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

  def error msg=nil
    return @error unless msg
    @error = App.error msg
  end

  def download
    unless File.exists?(@original)
      run "curl -L '#{@image}' --create-dirs -s -o '#{@original}'"

      if File.exists?(@original)
        App.log 'DOWNLOAD %s (%d kb)' % [@image, File.stat(@original).size/1024]
      else
        raise "Can't download source from %s" % @image
      end
    end

    @ext = info[1].downcase if info[2].to_s.include?('x')

    @original
  end

  def convert_base
    size = @size

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
    opts.push '-auto-orient'
    opts.push '-strip'
    opts.push "-quality #{@quality}"
    opts.push '-resize %s' % size
    opts.push '-unsharp %s' % ENV.fetch('UNSHARP_MASK') { '1x1+1+0' } if do_unsharp && @ext == 'jpeg'
    opts.push '-interlace Plane'
    opts.push '-background none' if @ext == 'png'

    if size.include?('^')
      opts.push '-gravity North'
      opts.push '-extent %s' % size.sub('^','')
    end

    run 'convert "%s" %s %s' % [@original, opts.join(' '), @resized]
  end

  def optimize
    case @ext
      when 'png'
        run "pngquant -f --output #{@resized} #{@resized}"
    end
  end

  def svg_error
    @ext = 'svg'

    %{<?xml version="1.0" standalone="no"?>
      <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
        <rect x="0" y="0" width="100%" height="100%" style="fill:#fee; stroke:#fcc; stroke-width:7px;" />
        <text x="50%" y="50%" fill="#800" text-anchor="middle" alignment-baseline="central">#{@error.capitalize}</text>
      </svg>
    }
  end

  def apply_watermark
    return unless @watermark

    image, gravity, percent = @watermark.split(':')
    gravity ||= 'SouthEast' # None, Center, East, Forget, NorthEast, North, NorthWest, SouthEast, South, SouthWest, West
    percent ||= 30

    run "composite -watermark 30% -gravity #{gravity} ./public/#{image}.png #{@resized} #{@resized}"
  end

  def resize
    raise @error if @error

    download

    return File.read(@original) if @ext == 'svg'

    if @size
      # do not apply resize if new width or height is less then original
      size = @size.split('x')
      size[1] ||= 0
      size = size
        .push(info[2].split('x'))
        .flatten
        .map(&:to_i)

      @size = info[2] if size[0] > size[2] || size[1] > size[3]
    else
      # if size not provided, only apply quality filter
      @size = info[2]
    end

    @resized = [App.root, "r/s#{@size}/q#{@quality}-#{sha1(@image+@watermark.to_s)}.#{@ext}"].join('/cache/')
    target_dir = @resized.sub(%r{/[^/]+$}, '')

    File.unlink(@resized)         if @reload && File.exist?(@resized)
    FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

    unless File.exists? @resized
      convert_base
      apply_watermark
      optimize
    end

    unless File.exists? @resized
      File.unlink(@original)
      raise 'Resize error'
    end

    @cache_path =
    if @as_webp
      @ext = 'webp'
      new_target = @resized.sub(/\.\w+$/, '.webp')
      run "cwebp -quiet -q #{@quality.to_i - 15} #{@resized} -o #{new_target}"
      new_target
    else
      @resized
    end

    File.read @cache_path
  rescue => e
    @error = e.message
    @error = 'Resize error' if @error.include?('No such file')
    svg_error
  end

  def info
    @info ||= `identify #{@original}`.split(' ')
  end
end

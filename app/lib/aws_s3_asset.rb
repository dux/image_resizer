# DONT FORGET
# to install awscli and imagemagic
raise '"identify" command not found (image magic not installed)' if `which identify`.to_s == ''
raise '"aws" command not found (aws-shell not installed)' if `which aws`.to_s == ''

# require 'aws-sdk'
require 'json'
require 'digest'

# options
# :max_width - resize image to desired max_width before upload
# :bucket
# :is_image - check if downloaded file is image
# upload_file('http://foo.bar/baz.jpeg', max_width:800)

# b = AwsS3Asset.new source: '/tmp/...'
# b = AwsS3Asset.new source: 'http://...', max_width: 200
# b.image_dimensions
# b.upload
# b.url

class AwsS3Asset
  attr_accessor :hash, :local_file

  class << self
    def config name
      App.config.send 'aws_%s' % name
    end

    def buckets
      `source .env && aws s3 ls`.split($/).map{ |line| line.split(' ', 3)[2] }
    end


    def upload args
      begin
        asset = AwsS3Asset.new args
        asset.image_dimensions[1] ? asset.upload : nil
      rescue ArgumentError => error
        puts 'AwsS3 Error: %s (%s)' % [error.message, args[:source]]
        nil
      end
    end
  end

  ###

  def initialize source:, bucket: nil, max_width: nil, is_image: nil, remote_path: nil, optimize: nil
    @source      = source
    @max_width   = max_width
    @is_image    = is_image
    @ext         = source.split('.').last.to_s.downcase.split('?').first
    @ext         = 'jpg' if @ext.to_s == '' || @ext.length > 4
    @is_image    = true if ['jpg', 'jpeg', 'gif', 'png'].include?(@ext)
    @is_image    = false if @ext == 'svg'
    @hash        = Digest::SHA1.hexdigest(@source+@max_width.to_s)
    @local_file  = './tmp/s3tmp-%s.%s' % [@hash, @ext]
    @optimize    = !!optimize

    raise "No bucket defined and no AWS_BUCKET set" unless config(:bucket)
    raise "Bucket #{config(:bucket)} has unallowed chars"   unless config(:bucket) =~ /^[\w\-]+$/

    if File.exist?(@local_file) && File.zero?(@local_file)
      File.delete(@local_file)
    end

    set_local_source
    check_image if @is_image

    remote_path ||= Time.now.strftime('%Y/%m/%d')
    @remote_file = '%s/%s.%s' % [remote_path, signature, @ext]
  end

  # returns full S3 path
  def url
    "https://s3.%s.amazonaws.com/%s/%s" % [config(:region), config(:bucket), @remote_file]
  end

  # gets image width and height using image magic
  def image_dimensions
    `identify '#{@local_file}'`.split(' ')[2].to_s.split('x').map(&:to_i)
  end

  # https://blurha.sh/
  def image_blur_hash
    image    = Magick::ImageList.new @local_file
    blurhash = Blurhash.encode(image.columns, image.rows, image.export_pixels)
    Base64.urlsafe_encode64 blurhash, padding: false
  end

  def signature
    data = [`sha1sum '#{@local_file}'`.split(' ').first]

    if @is_image
      data.push '%sx%s' % image_dimensions

      if App.config.blur_hash
        data.push image_blur_hash
      end
    end

    data.join('--')
  end

  def upload
    # resize image if needed
    if @max_width && @is_image
      run "convert '#{@local_file}' -resize '#{@max_width}x3000>' '#{@local_file}' 2>&1"
    end

    metadata = {}
    metadata['etag']         = '"%s"' % signature
    metadata['contant-type'] = 'image/%s' % @ext if @is_image

    command  = 'AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s' % [config(:access_key_id), config(:secret_access_key)]
    command += ' aws s3 cp %s s3://%s/%s --metadata-directive REPLACE --cache-control max-age=62000000,public --acl public-read' % [@local_file, config(:bucket), @remote_file]
    command += " --region '%s'" % config(:region)
    command += " --metadata '%s'" % metadata.to_json

    run command

    # File.unlink(@local_file)

    url
  end

  private

  def set_local_source
    if @source.start_with?('http')
      # run "curl #{@source} > #{@local_file}" unless File.exist?(@local_file)
      # fake chrome request because LinkedIN will not give avatar for curl requests
      run "curl '#{@source}' --max-time 5 -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.87 Safari/537.36' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-Mode: navigate' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,hr;q=0.8' --compressed > #{@local_file}" unless File.exist?(@local_file)
    else
      `cp '#{@source}' '#{@local_file}'`
    end

    # convert images to webp format before upload
    if @optimize
      new_target = @local_file.sub(/\.\w+/, '.webp')
      run "convert #{@local_file} #{new_target}"

      @local_file = new_target
      @remote_file.sub!(/\.\w+/, '.webp')
    end

    raise 'Local file not found' unless File.exist?(@local_file)
  end

  def check_image
    return if @ext == 'svg'

    # image magick to identify image, the third element in the return is widthxheight
    # raise error if image is has no height
    identify = `identify #{@local_file} 2>&1`.split(' ')
    raise ArgumentError, "Not an image" unless ['PNG', 'GIF', 'JPG', 'JPEG', 'WEBP'].index(identify[1])

    dimensions = identify[2].to_s.split('x').map(&:to_i)

    raise ArgumentError, "Not an image" unless dimensions[0] > 10 && dimensions[1] > 10
  end

  def run command
    puts command.gray
    puts '-'
    system command
  end

  def config name
    self.class.config name
  end
end

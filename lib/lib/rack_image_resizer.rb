# encodes resized image URLs

require 'base64'
require 'digest'
require_relative 'string'

module ::RackImageResizer
  extend self

  @@config = Struct.new(:secret, :server).new

  def set name, value
    @@config.send '%s=' % name, value
  end

  def config
    if block_given?
      yield @@config
    else
      @@config
    end
  end

  def checksum str, length = 2
    Digest::SHA1.hexdigest(App.config.secret+str)[0, length]
  end

  def header_checksum request
    str = request.env['HTTP_USER_AGENT'].to_s + request.env['HTTP_ACCEPT'].to_s
    checksum(str, 8)
  end

  ###

  def build opts
    opts[:p] ||= opts.delete(:proxy)
    opts[:i] ||= opts.delete(:image)
    opts[:s] ||= opts.delete(:size) || opts.delete(:w) || opts.delete(:width)
    opts[:e] ||= opts.delete(:onerror) if opts[:onerror]

    # return empty pixel unless self
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" if opts[:i].to_s == ''

    raise ArgumentError.new('Invalid URL, no https?:// found') unless opts[:i] =~ %r{^https?://}

    # reduce size of a hash by stripping 'https?://' - 7 characters
    opts[:i] = opts[:i].sub(%r{^(\w+)://}, '')
    prefix = $1 == 'https' ? 's' : 'p'
    opts[:i] = prefix + opts[:i]

    data = []

    # add base
    data.push Base64.urlsafe_encode64(opts.to_json).gsub(/=*\s*$/, '')

    # add check, 2 chars
    data.push checksum(data.first)

    # add extension
    ext = opts[:i].split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png', 'svg'].index(ext)
    data.push '.%s' % ext

    # return full url
    [App.config.server, data.join('')].join('/r/')
  end

  def upload_path request
    '%s/upload/%s' % [@@config.server, header_checksum(request)]
  end
end

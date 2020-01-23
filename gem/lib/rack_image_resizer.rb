# encodes resized image URLs

require 'base64'
require 'digest'
require_relative 'string'

module ::RackImageResizer
  extend self

  @@config = Struct.new(:secret, :server, :host).new

  def set name, value
    @@config.send '%s=' % name, value
  end

  def get name
    @@config.send(name) || ENV.fetch('RESIZER_%s' % name.to_s.upcase)
  end

  def config
    if block_given?
      yield @@config
    else
      @@config
    end
  end

  def prefix_it url
    url[0,1] == '/' ? get(:host) + url : url
  end

  ###

  def build opts
    opts[:p] ||= opts.delete(:proxy)
    opts[:i] ||= opts.delete(:image)
    opts[:s] ||= opts.delete(:size) || opts.delete(:w) || opts.delete(:width)
    opts[:e] ||= opts.delete(:onerror) if opts[:onerror]

    # return empty pixel unless self
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" if opts[:i].to_s == ''

    # add host as prefix to images if relative given
    opts[:i] = prefix_it opts[:i]
    opts[:e] = prefix_it opts[:e] if opts[:e]

    raise ArgumentError.new('Invalid URL, no https?:// found') unless opts[:i] =~ %r{^https?://}

    # reduce size of a hash by stripping 'https?://' - 7 characters
    opts[:i] = opts[:i].sub(%r{^(\w+)://}, '')
    prefix = $1 == 'https' ? 's' : 'p'
    opts[:i] = prefix + opts[:i]

    data = []

    # add base
    data.push Base64.urlsafe_encode64(opts.to_json).gsub(/=*\s*$/, '')

    # add check, 2 chars
    data.push Digest::SHA1.hexdigest(get(:secret)+data.first)[0,2]

    # add extension
    ext = opts[:i].split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png', 'svg'].index(ext)
    data.push '.%s' % ext

    # return full url
    [get(:server), data.join('')].join('/r/')
  end
end

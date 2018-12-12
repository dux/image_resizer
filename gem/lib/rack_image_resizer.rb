# encodes resized image URLs

require 'base64'
require_relative 'string'

module ::RackImageResizer
  extend self

  def set name, value
    raise 'not allowed' unless [:secret, :url, :host].include?(name)
    instance_variable_set '@%s' % name, value
  end

  def get name
    instance_variable_get('@%s' % name) || ENV.fetch('RESIZER_%s' % name.to_s.upcase)
  end

  ###

  def build opts
    opts[:i] ||= opts.delete(:image)
    opts[:s] ||= opts.delete(:size) if opts[:size]

    # return empty pixel unless self
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" if opts[:i].to_s == ''

    # add host as prefix to image if relative
    opts[:i] = get(:host) + opts[:i] if opts[:i][0,1] == '/'

    raise ArgumentError.new('Invalid URL, no https?:// found') unless opts[:i] =~ %r{^https?://}

    opts[:i] = opts[:i].sub(%r{^(\w+)://}, '')
    prefix = $1 == 'https' ? 's' : 'p'
    opts[:i] = prefix + opts[:i]

    data = []

    # add base
    data.push Base64.urlsafe_encode64(opts.to_json).gsub(/=*\s*$/, '')

    # add check
    data.push Digest::SHA1.hexdigest(get(:secret)+data.first)[0,4]

    # add extension
    ext = opts[:i].split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png', 'svg'].index(ext)
    data.push '.%s' % ext

    # return full url
    [get(:url), data.join('')].join('/r/')
  end
end

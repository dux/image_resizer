# encodes resized image URLs

require 'base64'
require_relative 'string'

module ::RackImageResizer
  extend self

  def resizer_secret
    @secret || ENV.fetch('RESIZER_SECRET')
  end

  def resizer_url
    @url    || ENV.fetch('RESIZER_URL')
  end

  def set name, value
    raise 'not allowed' unless [:secret, :url].include?(name)
    instance_variable_set '@%s' % name, value
  end

  ###

  # "http://foo.jpg".resize_image({ s: "222x222", q: 80 }
  # "http://foo.jpg".resize_image("^200x200")
  # "http://foo.jpg".resize_image - expcts size as param
  def get opts
    opts[:i] ||= opts.delete(:image)
    opts[:s] ||= opts.delete(:size) if opts[:size]

    # return empty pixel unless self
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" if opts[:i].to_s == ''

    opts[:i] = opts[:i].sub(%r{^(\w+)://}, '')
    prefix = $1 == 'https' ? 's' : 'p'
    opts[:i] = prefix + opts[:i]

    data = []

    # add base
    data.push Base64.urlsafe_encode64(opts.to_json).gsub(/=*\s*$/, '')

    # add check
    data.push Digest::SHA1.hexdigest(resizer_secret+data.first)[0,4]

    # add extension
    ext = opts[:i].split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png', 'svg'].index(ext)
    data.push '.%s' % ext

    # return full url
    [resizer_url, data.join('')].join('/r/')
  end
end

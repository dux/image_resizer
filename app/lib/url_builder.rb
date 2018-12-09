# uncodes and decodes resized image URLs

require 'base64'

class String
  # "http://foo.jpg".resize_image({ s: "222x222", q: 80 }
  # "http://foo.jpg".resize_image("^200x200")
  # "http://foo.jpg".resize_image - expcts size as param
  def resize_image opts=nil
    # return empty pixel unless self
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" if self.blank?

    image  = self
    image  = image.sub(%r{^(\w+)://}, '')
    prefix = $1 == 'https' ? 's' : 'p'
    image  = prefix + image

    to_encode =
    if opts
      opts = { s: opts } unless opts.is_a?(Hash)
      opts[:i] = image
      opts.to_json
    else
      image
    end

    data = []

    # add base
    data.push Base64.urlsafe_encode64(to_encode).gsub(/=*\s*$/, '')

    # add check
    data.push Digest::SHA1.hexdigest(ENV.fetch('RESIZER_SECRET')+data.first)[0,4]

    # add extension
    ext = self.split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png'].index(ext)
    data.push '.%s' % ext

    # return full url
    [ENV.fetch('RESIZER_URL'), data.join('')].join('/r/')
  end
end

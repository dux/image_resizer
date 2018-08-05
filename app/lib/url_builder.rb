# uncodes and decodes resized image URLs

require 'base64'

class String
  # "http://foo.jpg".resize_image({ s: "222x222", q: 80 }
  # "http://foo.jpg".resize_image("^200x200")
  def resize_image opts
    opts = { s: opts } unless Hash === opts
    opts[:i] = self

    data = []

    # add base
    data.push Base64.urlsafe_encode64(opts.to_json).gsub(/=*\s*$/, '')

    # add check
    data.push Digest::SHA1.hexdigest(ENV.fetch('RESIZER_SECRET')+data.first)[0,4]

    data.push '.'

    # add extension
    ext = opts[:i].split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png'].index(ext)
    data.push ext

    # return full url
    [ENV.fetch('RESIZER_URL'), data.join('')].join('/r/')
  end
end

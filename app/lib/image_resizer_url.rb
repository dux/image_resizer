require 'base64'

module ImageResizerUrl
  extend self

  JWT_ALGORITHM  = 'HS256'
  RESIZER_SECRET = ENV.fetch('RESIZER_SECRET')
  RESIZER_URL    = ENV['RESIZER_URL']    || 'http://localhost:4000'

  # eyJpbWFnZSI6Imh0dHA6Ly9pLmltZ3VyLmNvbS9rcnVyREdFLmpwZyIsInNpemUiOiIyMjJ4MjIyIn07c62.jpg
  def unpack url_part
    url_part    = url_part.sub(/\.\w+$/, '')
    base, check = url_part.slice!(0...-4), url_part

    # bad check
    unless Digest::SHA1.hexdigest(RESIZER_SECRET+base)[0,4] == check

    end

    data = JSON.load Base64.urlsafe_decode64(base)
    data = data.inject({}) { |it, (k,v)| it[k.to_sym] = v; it }
    data
  end

  # {
  #   image: "http://i.imgur.com/krurDGE.jpg",
  #   size:  "222x222"
  # }
  def url opts
    ap opts
    name = opts.delete(:name)

    data = []

    # add base
    data.push Base64.urlsafe_encode64(opts.to_json).gsub(/=*\s*$/, '')

    # add check
    data.push Digest::SHA1.hexdigest(RESIZER_SECRET+data.first)[0,4]

    # add name is defined
    if name
      name = '~%s' % name.to_s.gsub(/[^\w\-\.]+/,'_')[0,30]
      name = name.sub(/\.\w{3,4}$/,'')
    end

    data.push '.'

    # add extension
    ext = opts[:image].split('.').last.to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png'].index(ext)
    data.push ext

    [RESIZER_URL, data.join('')].join('/r/')
  end

end

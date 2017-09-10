### COPY THIS CLASS TO RAILS SERVER AND USE IT TO ENCODE URLS

# https://jwt.io/

module ImageResizerEncoder
  extend self

  JWT_ALGORITHM  = 'HS256'
  RESIZER_SECRET = ENV['RESIZER_SECRET']
  RESIZER_URL    = ENV['RESIZER_URL']    || 'http://localhost:4000'

  def pack data
    JWT.encode data, RESIZER_SECRET, JWT_ALGORITHM
  end

  def unpack text
    data = JWT.decode text, RESIZER_SECRET, true, { :algorithm => JWT_ALGORITHM }
    data[0].inject({}){|h,(k,v)| h[k.to_sym] = v; h}
  end

  def url opts
    # return opts[:image]

    ext = opts[:image].split('.').reverse[0].to_s.downcase
    ext = 'jpg' unless ['jpg', 'jpeg', 'gif', 'png'].index(ext)

    name = opts.delete(:name)
    if name
      name = '~%s' % name.to_s.gsub(/[^\w\-\.]+/,'_')[0,30]
      name = name.sub(/\.\w{3,4}$/,'')
    end

    enc = JWT.encode opts, RESIZER_SECRET, JWT_ALGORITHM

    '%s/r/%s%s.%s' % [RESIZER_URL, enc, name, ext]
  end

end

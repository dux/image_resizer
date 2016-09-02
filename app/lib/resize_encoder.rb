### COPY THIS CLASS TO RAILS SERVER AND USE IT TO ENCODE URLS

# https://jwt.io/

module ResizeEncoder
  extend self

  JWT_ALGORITHM  = 'HS256'
  RESIZER_SECRET = ENV['RESIZER_SECRET'] || 'secret'
  RESIZER_URL    = ENV['RESIZER_URL'] || 'http://localhost:9292'

  def pack(data)
    JWT.encode data, RESIZER_SECRET, JWT_ALGORITHM
  end

  def unpack(text)
    data = JWT.decode text, RESIZER_SECRET, true, { :algorithm => JWT_ALGORITHM }
    data[0]
  end

  def generate_url(opts)
    ext = opts[:image].split('.').last
    ext = 'jpg' if ext.to_s.length < 3 && ext.to_s.length > 4
    "#{RESIZER_URL}/r/#{pack(optd)}.#{ext}"
  end

end

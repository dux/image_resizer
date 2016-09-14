### COPY THIS CLASS TO RAILS SERVER AND USE IT TO ENCODE URLS

# https://jwt.io/

module ImageResizerEncoder
  extend self

  JWT_ALGORITHM  = 'HS256'
  RESIZER_SECRET = ENV['RESIZER_SECRET'] || 'secret'
  RESIZER_URL    = ENV['RESIZER_URL']    || 'http://localhost:9292'

  def pack(data, secret=nil)
    secret ||= RESIZER_SECRET
    JWT.encode data.to_json, secret, JWT_ALGORITHM
  end

  def unpack(text)
    data = JWT.decode text, RESIZER_SECRET, true, { :algorithm => JWT_ALGORITHM }
    JSON.parse(data[0]).inject({}){|h,(k,v)| h[k.to_sym] = v; h}
  end

  def generate_url(opts)
    ext = opts[:image].split('.').last
    opts[:image].gsub!(' ', '%20')
    ext = 'jpg' if ext.to_s.length < 3 && ext.to_s.length > 4
    "#{RESIZER_URL}/r/#{pack(opts)}.#{ext}"
  end

end

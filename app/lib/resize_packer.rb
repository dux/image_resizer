### COPY THIS CLASS TO RAILS SERVER AND USE IT TO ENCODE URLS

module ResizeEncoder
  extend self

  RESIZER_SECRET = ENV['RESIZER_SECRET'] || 'secret'
  RESIZER_URL    = ENV['RESIZER_URL'] || 'http://localhost:9292'

  def cipher(mode, data)
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc').send(mode)
    cipher.key = Digest::SHA512.digest(RESIZER_SECRET)
    cipher.update(data.to_s) << cipher.final
  end

  def pack(data)
    Base64.urlsafe_encode64(cipher(:encrypt, [data].to_json)).gsub(/\s/,'')
  end

  def unpack(text)
    JSON.parse(cipher(:decrypt, Base64.urlsafe_decode64(text)))[0]
  end

  def generate_url(opts)
    "#{RESIZER_URL}/r/#{pack(optd)}"
  end

end

#!/usr/bin/ruby

require 'sinatra'
require 'digest'
require 'json'
require 'base64'
require 'openssl'

### COPY THIS CLASS TO RAILS SERVER AND USE IT TO ENCODE URLS
class ResizePacker
  SECRET = 'BIG-SECRET-!!!'

  def self.cipher(mode, data)
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc').send(mode)
    cipher.key = Digest::SHA512.digest(SECRET)
    cipher.update(data.to_s) << cipher.final
  end

  def self.pack(data)
    Base64.urlsafe_encode64(cipher(:encrypt, [data].to_json)).gsub(/\s/,'')
  end

  def self.unpack(text)
    JSON.parse(cipher(:decrypt, Base64.urlsafe_decode64(text)))[0]
  end

end
### PACKER ENCODER CODE END

ROOT = Dir.getwd
error = nil

for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{ROOT}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

def md5(data)
  ret = Digest::MD5.hexdigest data
  ret[2,0] = '/'
  ret
end


class Image
  attr_reader :ext, :original, :resized

  def initialize(image, quality=80)
    @image = image
    @ext = image.split('.').reverse[0].to_s
    @ext = 'jpg' unless @ext.length > 2 && @ext.length < 5
    @ext = @ext.downcase
    @quality = quality < 10 ? 80 : quality
    @original = "#{ROOT}/cache/originals/#{md5(@image)}.#{@ext}"
  end

  def download(target=nil)
    `curl '#{@image}' --create-dirs -s -o '#{@original}'` unless File.exists?(@original)
    
    if dir = target.dup
      dir.gsub!(/\/[^\/]+$/,'')
      Dir.mkdir dir unless Dir.exists?(dir)
    end

    @original
  end

  def resize(size)
    resized = "#{ROOT}/cache/resized/#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"

    unless File.exists?(resized)
      download resized
      `convert '#{@original}' -quality #{@quality} -resize #{size}x2000 '#{resized}'` 
    end
    resized
  end

  def crop(size, gravity)
    width, height = size.to_s.downcase.split('x')
    height ||= width
    raise 'Image to large' if width.to_i > 1500 || height.to_i > 1500
    cropped = "#{ROOT}/cache/croped/#{width}x#{height}-q#{@quality}-#{md5(@image)}.#{@ext}"
    unless File.exists?(cropped)
      download cropped
      `convert #{@original} -quality #{@quality} -resize #{width}x#{height}^ -gravity #{gravity} -background black -extent #{width}x#{height} #{cropped}`
    end
    cropped
  end

end

class Pumatra < Sinatra::Base

  get "/" do
    response.headers['Content-type'] = "text/plain"

    return %[Sinatra image reizer by @dux

    /resize => ONLY ON DEV
    - image = source image
    - width = integer 10<->1000
    - crop = 200 || 200x300

    /pack?image=foo&crop=bar => ONLY ON DEV
    - just use pack insted of resize
    - render URL PACKED FOR PRODUCTION

    use ResizePacker class for resizeing on server
    - ResizePacker.pack({ image:'http://some-destinat.io/n.jpg', width:100 })
    - used packet/crypted string as prexix on /resize => /resize/somepackedshit[.jpg]
    ]
  end

  get '/pack' do
    return 'Unprotected requests are only allowed on local instances' unless ['127.0.0.1','0.0.0.0'].index(request.ip)

    return "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/resize/#{ResizePacker.pack(params)}.jpg"
  end

  get "/resize*" do
    if data=request.path.split(/\/|\./)[2] # recieved packed string
      begin
        params.merge! ResizePacker.unpack(data)
      rescue
        return "ERROR: Bad crypted string"
      end
    else
      return 'Unprotected requests are only allowed on local instances' unless ['127.0.0.1','0.0.0.0'].index(request.ip)
    end


    image = params[:image]
    return '[image] not defined' unless image.to_s.length > 1

    resize_width = params[:width].to_i
    crop_size = params[:crop]
    
    return '[width || crop] not defined' if resize_width < 10 && crop_size.to_s.length == 0

    img = Image.new(image, params[:q].to_i)

    response.headers['Content-type'] = "image/#{img.ext}"
    response.headers['Cache-control'] = 'public, max-age=10000000, no-transform' 

    if resize_width > 0
      return 'Image to large' if resize_width > 1500
      send_file(img.resize(resize_width), :disposition => 'inline')
    else
      gravity = params[:gravity].to_s.downcase
      gravity = 'North' if gravity.length == 0
      send_file(img.crop(crop_size, gravity), :disposition => 'inline')
    end
  end

  get '/crop' do

  end
end

if __FILE__ == $0
  Pumatra.run!
end


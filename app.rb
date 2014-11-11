#!/usr/bin/ruby

require 'sinatra'
require 'digest'

ROOT = Dir.getwd
error = nil

for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{ROOT}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

def md5(data)
  Digest::MD5.hexdigest data
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

  def download
    `curl '#{@image}' -s -o '#{@original}'` unless File.exists?(@original)
    @original
  end

  def resize(size)
    resized = "#{ROOT}/cache/resized/#{size}-q#{@quality}-#{md5(@image)}.#{@ext}"

    unless File.exists?(resized)
      download
      `convert '#{@original}' -quality #{@quality} -resize #{size}x2000 '#{resized}'` 
    end
    resized
  end

  def crop(size, gravity)
    width, height = size.downcase.split('x')
    height ||= width
    raise 'Image to large' if width.to_i > 1500 || height.to_i > 1500
    cropped = "#{ROOT}/cache/croped/#{width}x#{height}-q#{@quality}-#{md5(@image)}.#{@ext}"
    unless File.exists?(cropped)
      download
      `convert #{@original} -quality #{@quality} -resize #{width}x#{height}^ -gravity #{gravity} -background black -extent #{width}x#{height} #{cropped}`
    end
    cropped
  end

end

class Pumatra < Sinatra::Base
  def get_param(name)
    ret = params[name]
    unless ret.length > 0
      error = "[#{name}] not defined" 
      return false
    end
    ret
  end

  get "/" do
    response.headers['Content-type'] = "text/plain"

    return %[/resize
      - image = source image
      - width = integer 10<->1000
      - crop = 200 || 200x300
    ]
  end

  get "/resize" do
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


#!/usr/bin/ruby

require 'digest'
require 'json'
require 'base64'
require 'openssl'

[:resize_encoder, :image, :init].each { |lib| require_relative "./lib/#{lib}" }

class Resizer < Sinatra::Base

  def is_local
    ['127.0.0.1','0.0.0.0'].index(request.ip)
  end

  get "/" do
    return 'nothing here, bye' unless is_local

    File.read('./app/views/index.html')
  end

  get '/pack' do
    return 'Unprotected requests are only allowed on local instances' unless is_local

    url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/r/#{ResizeEncoder.pack(params)}.jpg"
    return %[<html><head></head><body><h3>On server</h3><pre>ResizePacker.generate_url(#{JSON.pretty_generate(params)})</pre>
      <hr />
      <h3>Will output</h3>
      <a href="#{url}">#{url}</a></body></html>]
  end

  get "/r*" do
    data = request.path.split('/')[2] # recieved packed string
    if data
      begin
        data.sub!(/\.\w{3,4}$/,'')
        params.merge! ResizeEncoder.unpack(data)
      rescue
        return "ERROR: Bad crypted string: #{$!.message}"
      end
    else
      return 'Unprotected requests are only allowed on development as /r?width=...&image=...' unless is_local
    end

    image = params[:image]
    return '[image] not defined' unless image.to_s.length > 1

    resize_width = params[:width].to_i
    crop_size = params[:crop]

    return '[width || crop] not defined' if resize_width < 10 && crop_size.to_s.length == 0

    img = Image.new(image, params[:q].to_i)

    response.headers['Content-type'] = "image/#{img.ext}"
    response.headers['Cache-control'] = 'public, max-age=10000000, no-transform'
    response.headers['ETag'] = Digest::MD5.hexdigest params.to_json

    if resize_width > 0
      return 'Image to large' if resize_width > 1500
      data = img.resize(resize_width)
    else
      gravity = params[:gravity].to_s.downcase
      gravity = 'North' if gravity.length == 0
      data = img.crop(crop_size, gravity)
    end

    send_file(data, :disposition => 'inline')
  end

end

if __FILE__ == $0
  Resizer.run!
end


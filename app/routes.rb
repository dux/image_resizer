# main app routes

get '/' do
  @version = File.read('.version')

  erb ENV['RACK_ENV'].downcase.to_sym
end

get '/pack' do
  @image = params.delete(:image)
  @size  = params.delete(:size)

  @url1  = @image.resized(s: @size, w: params[:w])
  @url2  = '%s?s=%s' % [@image.resized, @size]

  erb :pack
end

get '/r/*' do
  App.clear_cache

  @params = unpack_url params[:splat].first

  render_image
end

get '/log' do
  return 'secret not defined' unless params[:secret] == ENV.fetch('RESIZER_SECRET')

  lines = `tail -n 2000 ./log/production.log`.split($/).reverse.join("\n")

  content_type :text

  lines
end

get '/favicon.ico' do
  data = File.read './public/favicon.ico'

  response.headers['cache-control']  = 'public, max-age=10000000, no-transform'
  response.headers['content-type']   = "image/png"
  response.headers['content-length'] = data.bytesize

  data
end

get '/ico/:domain' do
  ico  = find_ico params[:domain]
  data = File.read(ico)

  content_type =
  if data.to_s.include?('</body>')
    data = %[<?xml version="1.0" standalone="no"?>
    <svg width="1px" height="1px" xmlns="http://www.w3.org/2000/svg">
      <desc>ico for #{params[:domain]} not found</desc>
    </svg>]

    "image/svg+xml"
  else
    cli = `identify #{ico}`.split(/\s+/)
    ext = cli[1] || 'png'

    'image/%s' % ext.downcase
  end

  deliver_data data,
    etag:         '"%s"' % Digest::SHA1.hexdigest(data),
    content_type: content_type
end

# only in development
if App.is_local?
  get '/test' do
    @movies_json = File.read './public/movies.js'

    erb :test
  end

  get '/r' do
    App.clear_cache

    @params = params

    render_image
  end
end

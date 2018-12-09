# main app routes

get '/' do
  @version = File.read('.version')

  erb ENV['RACK_ENV'].downcase.to_sym
end

get '/pack' do
  @image = params.delete(:image)
  @size  = params.delete(:size)
  @url1  = @image.resize_image(@size)
  @url2  = '%s?s=%s' % [@image.resize_image, @size]

  erb :pack
end

get '/r/*' do
  App.clear_cache

  @params = unpack_url params[:splat].first

  render_image
end

get '/log' do
  return 'secret not defined' unless params[:secret] == ENV.fetch('RESIZER_SECRET')

  lines = `tail -n 1000 ./log/production.log`.split($/).reverse.join("\n\n")

  content_type :text

  lines
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

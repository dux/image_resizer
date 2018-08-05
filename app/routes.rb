# main app routes

get '/' do
  @version = File.read('.version')

  erb ENV['RACK_ENV'].downcase.to_sym
end

get '/pack' do
  image = param.delete(:image)
  @url = image.resize_image(params[:size])

  erb :pack
end

get '/r/*' do
  App.clear_cache

  data    = params[:splat].first.sub(/\.\w{3,4}$/,'')
  @params = unpack_url data

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

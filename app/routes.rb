# main app routes

get '/' do
  @version = File.read('.version')

  erb ENV['RACK_ENV'].downcase.to_sym
end

get '/pack' do
  @url = ImageResizerUrl.get(@params)

  erb :pack
end

get '/r/*' do
  data    = params[:splat].first.sub(/\.\w{3,4}$/,'')
  @params = ImageResizerUrl.unpack data

  render_image
end

get '/log' do
  return 'secret not defined' unless params[:secret] == ENV.fetch('RESIZER_SECRET')

  lines = `tail -n 500 #{App::LOG_FILE}`.split($/).reverse.join($/)

  content_type :text

  lines
end

# only in development
if App.is_local?
  get '/r' do
    @params = params

    render_image
  end
end

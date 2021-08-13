before do
  # response.headers['Access-Control-Allow-Origin'] = App.config.allow_origin
  # response.headers['Access-Control-Allow-Headers'] = '*'
  # response.headers['Access-Control-Request-Method'] = 'POST'

  # define etag and return from cache if possible
  @etag = '"%s"' % Digest::SHA1.hexdigest(request.url)
  response.header['X-Frame-Options'] = 'ALLOWALL'
  response.header['Access-Control-Allow-Origin'] = '*'
end

###

# only in development
if App.dev?
  get '/upload/test' do
    erb :upload_test
  end

  get '/resize_test' do
    erb :resize_test
  end

  get '/ico_test' do
    erb :ico_test
  end

  get '/upload_test' do
    erb :upload_test
  end

  get '/r' do
    App.clear_cache

    @params = params

    render_image
  end
end

###

get('/healthcheck') { 'ok' }
get('/ok') { 'ok' }

options '/*' do
  response.headers['Allow'] = 'OPTIONS, GET, HEAD, POST'
  response.headers['Cache-Control'] = 'max-age=604800'
  status 204
end

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
  rescued do
    App.clear_cache

    @params = RackImageResizer.resize_url_unpack params[:splat].first, params

    render_image
  end
end

get '/log/:secret' do
  raise 'secret not defined' unless params[:secret] == ENV.fetch('RESIZER_SECRET')

  lines = `tail -n 2000 ./log/app.log`.split($/).reverse.join("\n")

  content_type :text

  "#{`du -sh ./cache`}\n\n" +lines
end

get '/favicon.ico' do
  data = File.read './public/favicon.ico'

  response.headers['cache-control']  = 'public, max-age=10000000, no-transform'
  response.headers['content-type']   = "image/png"
  response.headers['content-length'] = data.bytesize

  data
end

get '/ico/:domain' do
  ico  = find_ico RackImageResizer.decode params[:domain]
  data = File.read(ico)

  content_type =
  if data.to_s.include?('</body>')
    data = %[<?xml version="1.0" standalone="no"?>
    <svg width="1px" height="1px" xmlns="http://www.w3.org/2000/svg">
      <desc>ico for #{params[:domain]} not found</desc>
    </svg>]

    "image/svg+xml"
  elsif ico =~ /\.ico$/
    'image/vnd.microsoft.icon'
  else
    cli = `identify #{ico}`.split(/\s+/)
    ext = cli[1] || 'png'

    'image/%s' % ext.downcase
  end

  deliver_data data,
    etag:         '"%s"' % Digest::SHA1.hexdigest(data),
    content_type: content_type
end

get '/upload' do
  if App.dev?
    redirect RackImageResizer.upload_path
  else
    error 'Checksum not provided'
  end
end

get '/upload/:time_check' do
  time_check

  @is_image = params[:is_image] == 'true' || params[:max_width]
  @opts = []
  @opts.push 'is_image=%s' % (@is_image ? true : false)
  @opts.push "max_width=%s" % params[:max_width] if params[:max_width]

  erb :upload
end

post '/upload/:time_check' do
  time_check

  opts = {}

  if params[:remote_url]
    local = Pathname.new './cache/dl/%s' % params[:remote_url].gsub(/[^\w\.]/, '')

    unless local.exist?
      App.run "curl --max-time 10 -L '#{params[:remote_url]}' --create-dirs -s -o '#{local}'"
    end

    opts[:source] = local.to_s
    file_name = params[:remote_url].split('/').last
  else
    opts[:source] = params[:image]['tempfile'].path
    file_name     = params[:image][:filename]
  end

  opts[:max_width] = params[:max_width] ? params[:max_width].to_i : nil
  opts[:is_image]  = params[:max_width] || params[:is_image].to_s == 'true' ? true : false

  s3 = AwsS3Asset.new **opts
  file_url = s3.upload

  content_type :json

  file_name = file_name.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

  {
    url:        file_url,
    name:       file_name,
    size:       File.size(s3.local_file),
    dimensions: s3.image_dimensions
  }.to_json
rescue => e
  App.log_error e
  'Error: %s' % e.message
end

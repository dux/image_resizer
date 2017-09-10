require 'dotenv'
Dotenv.load

port            4000

Dir.mkdir 'tmp' unless Dir.exists?('tmp')

if ENV['RACK_ENV'] == 'production'
  # daemonize true
  threads 0, 32
  pidfile         './tmp/puma.pid'
  state_path      './tmp/puma.state'
  stdout_redirect './tmp/puma_stdout', './tmp/puma_stderr'
end

Thread.new do
  while true
    # delete all cache files which where not accessd in 2 days
    `find ./cache -depth -type f -atime +2 -delete`
    sleep 3600
  end
end


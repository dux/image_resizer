# puma -C production_config.rb
# https://github.com/puma/puma/blob/master/examples/config.rb

root = "#{Dir.getwd}"
# activate_control_app "tcp://127.0.0.1:9393", { no_token: true }
# bind "unix:///tmp/puma_sinatra_resizer.sock"
# pidfile "#{root}/tmp/pids/puma_sinatra_resizer.pid"
rackup "#{root}/config.ru"
# state_path "#{root}/tmp/pids/puma_sinatra_resi  zer.state"
daemonize false
threads 1, 24
workers 2
environment 'production'
# quiet 
# tag 'puma sinatra resizer'
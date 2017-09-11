require 'dotenv'
Dotenv.load

port 4000

for dir in ['tmp', 'log']
  Dir.mkdir dir unless Dir.exists?(dir)
end

if ENV['RACK_ENV'] == 'production'
  daemonize true
  threads 0, 32
  pidfile         './tmp/puma.pid'
  state_path      './tmp/puma.state'
  stdout_redirect './tmp/puma_stdout', './tmp/puma_stderr'
end

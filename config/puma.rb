require 'dotenv'
Dotenv.load

for dir in ['tmp', 'log']
  Dir.mkdir dir unless Dir.exists?(dir)
end

@port = 4000

port @port

if ENV['RACK_ENV'] == 'production'
  # daemonize true
  port 4000
  workers 2
  threads 1, 32
  pidfile         './tmp/puma.pid'
  state_path      './tmp/puma.state'
  stdout_redirect './tmp/puma_stdout', './tmp/puma_stderr'
end


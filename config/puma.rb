require 'dotenv'
Dotenv.load

port 4000

if ENV['RACK_ENV'] == 'production'
  # daemonize true
  workers 2
  threads 1, 32
  pidfile         './tmp/puma.pid'
  state_path      './tmp/puma.state'
  stdout_redirect './tmp/puma_stdout', './tmp/puma_stderr'
end


require 'dotenv'
Dotenv.load

if ENV['RACK_ENV'] == 'production'
  daemonize true
  port            80
  workers         2
  threads         1, 32
  pidfile         './tmp/puma.pid'
  state_path      './tmp/puma.state'
  stdout_redirect './tmp/puma_stdout', './tmp/puma_stderr'
else
  port 4000
end


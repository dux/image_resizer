#!/usr/bin/env ruby

require 'colorize'
require 'dotenv'

Dotenv.load

ENV['REMOTE_PORT'] ||= '22'

def die(what)
  puts what.red
  exit
end

def config(name)
  name = name.to_s.upcase
  ENV[name] || die("No ENV config for #{name}")
end

def local(what)
  puts "\n#{what.green}"
  system "#{what} 2>&1"
end

def remote(what)
  local %[ssh #{config(:remote_server)} -t -p #{config(:remote_port)} "cd #{config(:remote_path)}; #{what}"]
end

def sudo(user, what=nil)
  if what
    what = "-u #{user} #{what}"
  else
    what = user
  end
  remote "echo #{config(:ssh_pass)} | sudo -S #{what}"
end

###

remote 'git pull'


require 'dotenv'
require 'colorize'
require 'awesome_print'

Dotenv.load

def run command, *args
  command += ' %s' % args.join(' ') if args.first
  puts command.yellow
  system command
end

###

task :default do
  system 'rake -T'
end

desc 'Run development server'
task :dev do
  run 'find ./app | entr -r bundle exec puma -p 4000 -t 0:16'
end

desc 'Run production server'
task :production do
  run 'bundle exec puma -e production -w 2 -t 0:32'
end

desc 'Clear cache'
task :cc do
  run 'find ./cache -depth -type f -atime 2 -delete'
end

desc 'Get console'
task :console do
  require_relative 'app/libs'

  require 'pry'
  AwesomePrint.pry!
  Pry.start
end

desc 'Install dependecies'
task :install do
  `mkdir -p ./log`

  libs = 'webp imagemagick pngquant jpegoptim'
  sudo = `whoami`.chomp == 'root' ? '' : 'sudo'

  if `which brew`.to_s != ''
    system 'brew upgrade %s' % libs
    run 'brew install entr'

  elsif `which apt-get`.to_s != ''
    system "#{sudo} apt-get install -y %s" % libs

  elsif `which apk`.to_s != ''
    system "#{sudo} apk add -y libffi-dev %s" % libs

  else
    puts 'pls install libs: %s' % libs

  end
end

desc 'Install dependecies'
task :test do
  puts 'run "%s" if you want to clear resizer cache' % 'rm -rf ./cache/r'.yellow
  ARGV.shift
  unless ARGV[0]
    puts 'No input given!'.red
    puts 'Example: rake test http://i.imgur.com/krurDGE.jpg http://localhost:4000'
    exit
  end

  run './bin/test', *ARGV
  exit
end

desc 'Rspec test'
task :rspec do
  run 'rspec'
end

desc 'Update resizer & restart server'
task :update do
  run 'git stash'
  run 'git pull'
  run 'bundle install'
  run 'sudo service nginx restart'
end

desc 'Generate nginx conf file'
task :nginx do
  server = ENV.fetch('RESIZER_SERVER').split('/').last

  conf = File.read('config/nginx.conf')
  conf = conf.gsub('$domain', server)
  conf = conf.gsub('$root', `pwd`.chomp)

  puts conf
end

task :test_upload do
  require_relative 'app/libs'

  s3a = AwsS3Asset.new(source: 'https://i.imgur.com/UPc8aYn.jpg')
  s3a.upload
  puts s3a.url
end

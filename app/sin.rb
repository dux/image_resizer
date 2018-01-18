#!/usr/bin/ruby

require 'digest'
require 'json'
require 'base64'
require 'openssl'
require 'dotenv'
require 'bundler/setup'
require 'logger'
require 'awesome_print'

Dotenv.load
Bundler.require

require_relative 'lib/image_url'
require_relative 'lib/image_resizer'

module App
  extend self

  ICON     = File.read('./public/favicon.ico')
  LOG_FILE = './log/%s.log' % ENV['RACK_ENV']
  LOGGER   = Logger.new(LOG_FILE, 'weekly')
  ROOT     = File.expand_path('..', File.dirname(__FILE__))

  LOGGER.datetime_format = '%F %R'

  def call env
    app = new env
    app.router
    app.deliver
  end

  def log text
    LOGGER.info text
  end

  def is_local?
    ENV.fetch('RACK_ENV') == 'development'
  end

  def root
    ROOT
  end

  def die text
    puts text.red
    exit
  end
end

# exit unless imagemagic convert is found
App.die('ImageMagic convert not found in path') if `which convert` == ''

# create needed folers
for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{App.root}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

# delete cache older than two days
`find ./cache -depth -type f -atime +2 -delete`

load './app/routes.rb'
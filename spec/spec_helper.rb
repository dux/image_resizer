ENV['RACK_ENV'] = 'test'
# auto migrate database

# basic config
RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :json, CustomFormatterClass
end

require 'digest'
require 'json'
require 'base64'
require 'openssl'
require 'dotenv'
require 'bundler/setup'
require 'logger'
require 'awesome_print'

Dotenv.load

require './app/app'

require './app/lib/image_resizer_url'
require './app/lib/image_resizer'
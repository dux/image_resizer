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

require_relative 'lib/app'
require_relative 'lib/extensions'
require_relative 'lib/image_resizer'
require_relative '../gem/lib/rack_image_resizer'

ENV['RESIZER_URL']         ||= 'http://localhost:4000'
ENV['RESIZER_CACHE_CLEAR'] ||= '2d'

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
require_relative 'lib/url_builder'
require_relative 'lib/image_resizer'
require_relative 'helper'

ENV['RESIZER_URL']         ||= 'http://localhost:4000'
ENV['RESIZER_CACHE_CLEAR'] ||= '2d'

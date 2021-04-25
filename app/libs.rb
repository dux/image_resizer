require 'digest'
require 'json'
require 'base64'
require 'openssl'
require 'dotenv'
require 'bundler/setup'
require 'logger'
require 'awesome_print'
require 'hash_wia'

Dotenv.load
Bundler.require

require_relative 'lib/app'
require_relative 'lib/image_resizer'
require_relative 'lib/aws_s3_asset'
require_relative '../lib/rack_image_resizer'

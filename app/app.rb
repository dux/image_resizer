#!/usr/bin/ruby

require 'digest'
require 'json'
require 'base64'
require 'openssl'
require 'dotenv'
require 'bundler/setup'

Dotenv.load
Bundler.require

raise 'RACK_ENV not suported' unless ['production', 'development'].index ENV.fetch('RACK_ENV')

class Object
  def r what=nil
    raise StandardError, what
  end
end

ROOT = Dir.getwd

for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{ROOT}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

[:resizer, :resizer_encoder, :resizer_image].each { |lib| require_relative "./lib/image_#{lib}" }

`find ./cache -depth -type f -atime +2 -delete`


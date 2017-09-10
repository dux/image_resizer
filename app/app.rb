#!/usr/bin/ruby

require 'digest'
require 'json'
require 'base64'
require 'openssl'
require 'dotenv'
require 'bundler/setup'

Dotenv.load

Bundler.require

class Object
  def r(what=nil)
    raise StandardError, what
  end
end

ROOT = Dir.getwd

for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{ROOT}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

def md5(data)
  ret = Digest::MD5.hexdigest data
  ret[2,0] = '/'
  ret
end

[:resizer, :resizer_encoder, :resizer_image].each { |lib| require_relative "./lib/image_#{lib}" }


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

require_relative 'app'
require_relative 'routes'

require_relative 'lib/image_resizer_url'
require_relative 'lib/image_resizer'
require_relative 'render_image'

# exit unless imagemagic convert is found
App.die('ImageMagic convert not found in path') if `which convert` == ''

# exit uneless unsuported env
App.die('Unsupported RACK_ENV') unless ['production', 'development'].include?(ENV.fetch('RACK_ENV'))

# create needed folers
for dir in ['cache','cache/originals', 'cache/resized', 'cache/pages', 'cache/croped']
  dir = "#{App.root}/#{dir}"
  Dir.mkdir(dir) unless Dir.exists?(dir)
end





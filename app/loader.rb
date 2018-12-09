#!/usr/bin/ruby

require_relative 'libs'
require_relative 'routes'
require_relative 'router_helper'

# exit unless imagemagic convert is found
App.die('ImageMagic convert not found in path') if `which convert` == ''

# exit uneless unsuported env
App.die('Unsupported RACK_ENV') unless ['production', 'development'].include?(ENV.fetch('RACK_ENV'))

# secret must be present
App.die('RESIZER_SECRET not defined') unless ENV['RESIZER_SECRET']

`rm -rf ./cache` if
  App.is_local? &&
  Dir.exists?('./cache') &&
  `find ./cache -type f`.length > 0

puts '* Clearing cached images every %s' % ENV['RESIZER_CACHE_CLEAR']




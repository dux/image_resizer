#!/usr/bin/ruby

require_relative 'libs'
require_relative 'routes'
require_relative 'router_helper'

puts '* Clearing staled cache older then %s days' % App::CLEAR_INTERVAL

# exit unless imagemagic convert is found
App.die('ImageMagic convert not found in path') if `which convert` == ''

# exit uneless unsuported env
App.die('Unsupported RACK_ENV') unless ['production', 'development'].include?(ENV.fetch('RACK_ENV'))

# secret must be present
App.die('RESIZER_SECRET not defined') unless ENV['RESIZER_SECRET']

# clear stale cache on start
App.clear_cache_do




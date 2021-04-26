#!/usr/bin/ruby

require_relative 'libs'
require_relative 'routes/routes'
require_relative 'routes/helper'

puts '* Clearing staled cache older then %s days' % App.config.clear_interval

# exit unless imagemagic convert is found
App.die('ImageMagic convert not found in path') if `which convert` == ''

# exit uneless unsuported env
App.die('Unsupported RACK_ENV') unless ['production', 'development'].include?(App.config.env)

# secret must be present
App.die('RESIZER_SECRET not defined') unless RackImageResizer.config.secret

# clear stale cache on start
App.clear_cache_do

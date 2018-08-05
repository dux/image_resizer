#!/usr/bin/ruby

require_relative 'libs'
require_relative 'routes'

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





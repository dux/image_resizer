version = File.read File.expand_path '../.version', __dir__

Gem::Specification.new 'rack_image_resizer', version do |s|
  s.summary     = 'Ruby rack image resizer'
  s.description = 'Simple and fast ruby image resize server. Image magic in backend, converts to webp if possible.'
  s.authors     = ["Dino Reic"]
  s.email       = 'reic.dino@gmail.com'
  s.files       = Dir['./lib/*.rb']
  s.homepage    = 'https://github.com/dux/rack_image_resizer'
  s.license     = 'MIT'

  s.add_runtime_dependency 'fast_blank', '~> 1'
end

source 'https://rubygems.org'

if @inferred_plugins
  print 'Install system libs? (y/N): '

  if $stdin.gets.chomp.upcase == 'Y'
    puts 'WEBP encoder https://github.com/le0pard/webp-ffi'
    if `which apt-get`.to_s == ''
      for lib in %w{libjpg libpng libtiff webp}
        system "brew install #{lib}"
      end
    else
      system 'sudo apt-get install libjpeg-dev libpng-dev libtiff-dev libwebp-dev'
    end
  end
end

# gem 'iodine'
gem 'rack'
gem 'json'
gem 'dotenv'
gem 'sinatra'
gem 'webp-ffi'
gem 'fast_blank'

group :development do
  gem 'awesome_print'
  gem 'puma'
  gem 'colorize'
  gem 'rerun'
  gem 'pry'
end

group :test do
  gem 'rspec'
end

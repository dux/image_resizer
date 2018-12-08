source 'https://rubygems.org'

if @inferred_plugins
  print 'Install system libs? (y/N): '

  if $stdin.gets.chomp.upcase == 'Y'
    puts 'WEBP encoder https://github.com/le0pard/webp-ffi'

    if `which apt-get`.to_s == ''
      system "brew install libjpg libpng libtiff webp imagemagick pngquant jpegoptim"
    else
      system 'sudo apt-get install libjpeg-dev libpng-dev libtiff-dev libwebp-dev imagemagick pngquant jpegoptim'
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

Sinatra/ImageMagic image resizer
=====================

Fast and stable image resizer, written in Ruby

Delivers `webp` images to browsers that support the format.

## To use on a client

```ruby
require "rack_image_resizer"

RackImageResizer.config do |c
  c.secret = "foobarbaz"
  c.server = "https://resizer.myapp.com"
end

# RackImageResizer.build s: '^200x100'

@image.url.resized("200")      # resize image width to 200px
@image.url.resized("x200")     # resize image height to 200px
@image.url.resized("200x200")  # resize image to fix 200x200 box
@image.url.resized("^200x200") # resize crop image width to 200x200
@image.url.resized("^200")     # resize crop image width to 200x200
@image.url.resized("u^100")    # resize crop image width to 100x100 and apply unsharp mask

# or
@image.url.resized + '?s=x200' # dinamicly assign resize attributes
```

### To add and watermark

Define `image:gravity:opacity-percent`.

Image: PNG in public folder of image resize server. Example `./public/watermark1.png`.
Gravity: None, Center, East, Forget, NorthEast, North, NorthWest, SouthEast (default), South, SouthWest, West
Opacity-percent: 30 - default.

Following code will apply watermark to lower right corner of the image, width 400px.

```ruby
@image.url.resized(s: 400, w: "watermark1:SouthEast:30")
```

## To force refresh image

You need to append `reload` parameter with first 5 chars of RESIZER_SECRET.

`'?reload=%s' % ENV.fetch('RESIZER_SECRET')[0,5]`

## To install on a server

Clone and bundle

```
git clone https://github.com/dux/image_resizer.git
cd image_resizer
bundle install
rspec
```

add to `.env`

```
RESIZER_SECRET=...
RACK_ENV=production
RESIZER_CACHE_CLEAR=2d  # clear unacceded images every 2 days
```

install command line apps

```
rake install
# sudo apt install -y imagemagick pngquant jpegoptim webp
```

Run via puma or passanger, it is a rack app.

## All the tasks

`rake`

```
rake cc          # Clear cache
rake console     # Get console
rake dev         # Run development server
rake install     # Install dependecies
rake production  # Run production server
rake rspec       # Rspec test
rake test        # Install dependecies
```

## Run in development

`rake dev`

or

`puma -p 4000`


## URL doc

/r

* [i]mage     = source image
* [s]ize      = width x height
* [q]uality   = quality (10 - 100)
* [w]atermark = image:gravity:opacity-percent
* on[e]error  = image to show in case of error ("blank" to hide errors)

/pack?image=http://.../foo.jpg&size=200

## View log

View last 2000 log entries

`/log?secret=ENV[RESIZER_SECRET]`

## why?

Small, fast & has everything a dev needs


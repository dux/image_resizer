Sinatra/ImageMagic image resizer
=====================

Fast and stable image resizer, written in Ruby

Delivers `webp` images to browsers that support the format.

## To use on a client

```ruby
require "./app/lib/url_builder"

ENV["RESIZER_SECRET"] = "foobarbaz"
ENV["RESIZER_URL"]    = "https://resizer.myapp.com"

@image.url.image_resize("200")      # resize image width to 200px
@image.url.image_resize("x200")     # resize image height to 200px
@image.url.image_resize("200x200")  # resize image to fix 200x200 box
@image.url.image_resize("^200x200") # resize crop image width to 200x200
```

## To install on a server

Install image magic

```
git clone https://github.com/dux/rack_image_resizer.git
cd rack_image_resizer
bundle install
rspec
```

add to `.env`

```
RESIZER_SECRET=...
RACK_ENV=production
RESIZER_CACHE_CLEAR=2d  # clear unacceded images every 2 days
```

Run via puma or passanger, it is a rack app.

## In development

`bash ./run_development`

or

`puma -p 4000`

In root you will find image resize tester.

/r

* image   = source image
* size    = width x height
* quality = quality (10 - 100)

/pack?image=http://.../foo.jpg&size=200

* just use pack insted of resize
* render URL PACKED FOR PRODUCTION

/r/HASH.jpg => production

### localhost examples

http://0.0.0.0:4000/r?size=200&image=https://i.imgur.com/jQ55JGT.jpg

http://0.0.0.0:4000/r?size=x200&image=https://i.imgur.com/jQ55JGT.jpg

http://0.0.0.0:4000/r?size=200x300&image=https://i.imgur.com/jQ55JGT.jpg

http://0.0.0.0:4000/r?size=^200x200&image=https://i.imgur.com/jQ55JGT.jpg

## crontab clear cache

1 * * * * /home/user/apps/rack_image_resizer/bin/clear_cache

Check installation with `rspec`

## In your ruby app

Copy `./lib/image_resizer_url.rb` to `..app/lib`

Add the same secret to ENV and add RESIZER_URL ENV var

```
RESIZER_SECRET=...
RESIZER_URL=https://resizer.ypurapp.com
```

## View log

View last 1000 log entries

`/log?secret=ENV[RESIZER_SECRET]`

## why?

Small, fast & has everything I need


Sinatra/ImageMagic image resizer
=====================

Fast and stable image resizer, written in Ruby

/r

* image  = source image
* size   = width x height
* width  = width
* height = height
* q      = quality (10 - 100)

/pack?image=foo&size=bar

* just use pack insted of resize
* render URL PACKED FOR PRODUCTION

/r/HASH.jpg => production

Copy ImageResizer class for resizeing on production server.

* ImageResizerUrl.get({ image:'http://some-destinat.io/n.jpg', width:100 })


### localhost examples

http://0.0.0.0:4000/r?size=200&image=https://i.imgur.com/jQ55JGT.jpg

http://0.0.0.0:4000/r?size=200x300&image=https://i.imgur.com/jQ55JGT.jpg

http://0.0.0.0:4000/r?width=200&image=https://i.imgur.com/jQ55JGT.jpg


### crontab clear cache

1 * * * * /home/user/apps/rack_image_resizer/bin/clear_cache && curl -fsS --retry 3 https://hchk.io/sid > /dev/null


### Production installation

Clone the app

`git clone https://github.com/dux/rack_image_resizer.git image_resizer`

chdir an bundle

`cd image_resizer`

`bundle`

add to `.env`

```
RESIZER_SECRET=...
RACK_ENV=production
```

Install image magic

Check installation with `rspec`

### In your ruby app

Copy `./lib/image_resizer_url.rb` to `..app/lib`

Add the same secret to ENV and add RESIZER_URL ENV var

```
RESIZER_SECRET=...
RESIZER_URL=https://resizer.ypurapp.com
```

Resize images with `ImageResizerUrl.get({image: "http://...", size:  "200x200"})`

### why?

Small, fast & has everything I need


Ruby sinatra image resizer
=====================

Sinatra / Puma optimzed very fast and stable image resizer

/resize => ONLY ON DEV

* image = source image
* width = integer 10<->1000
* crop = 200 || 200x300

/pack?image=foo&crop=bar => ONLY ON DEV

* just use pack insted of resize
* render URL PACKED FOR PRODUCTION

use ResizePacker class for resizeing on server

* ResizePacker.pack({ image:'http://some-destinat.io/n.jpg', width:100 })
* used packet/crypted string as prexix on /resize => /resize/somepackedshit[.jpg]


### examples

http://0.0.0.0:9292/resize?crop=200&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg

http://0.0.0.0:9292/resize?crop=200x300&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg

http://0.0.0.0:9292/resize?width=200&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg


### how to run?

puma or ./run_development.bash

./run_production.bash

### why?

1. I made node resizer as well (https://github.com/dux/node-irp), this is better, use this. Run it with puma, it is even faster and more stable.
2. Other solutions are meh, slow and resource intensive


### about


@dux in 2014
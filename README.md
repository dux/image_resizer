Ruby sinatra image resizer
=====================

Sinatra / Puma optimzed very fast and stable image resizer

/resize => UNACKED PARAMS ONLY ON DEV

* image = source image
* width = integer
* crop = 200 || 200x300

/pack?image=foo&crop=bar => ONLY ON DEV

* just use pack insted of resize
* render URL PACKED FOR PRODUCTION

use ResizePacker class for resizeing on server

* ResizePacker.pack({ image:'http://some-destinat.io/n.jpg', width:100 })
* ResizePacker.generate_url({ image:'http://some-destinat.io/n.jpg', width:100 })

```
http://localhost:9292/r/5x5g4maheKCb0_fqBmwLiihTgc8iduV4gCQSyU3gF9i7H6gPjDdrDjlNjUb9ybJRSwHNo2jQ9Z0aOrSn-KoRvFk5cS9Pp_MlOiqyXQJ_auS0hQS_22jO2af09xueWdDOIXnukBvZcvx322E52wUDbL9cwxAHiRzrpaTgG7EJ8iqI9zALF7_M0UfLDCFrtsKVRHLymPEQlQhqEzOnxQ-G4w==.jpg
```


### examples

http://0.0.0.0:9292/r?crop=200&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg

http://0.0.0.0:9292/r?crop=200x300&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg

http://0.0.0.0:9292/r?width=200&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg


### how to run?

puma or ./run_development.bash

./run_production.bash

### why?

Small, fast & has everything I need


### about

@dux in 2014 - 2016
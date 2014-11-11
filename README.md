Ruby sinatra image resizer
=====================

Sinatra / Puma optimzed very fast and stable image resizer

/resize

* image = source image
* width = integer 10<->1000
* crop = 200 || 200x300

### examples

http://0.0.0.0:9292/resize?crop=200&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg

http://0.0.0.0:9292/resize?crop=200x300&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg

http://0.0.0.0:9292/resize?width=200&image=http://www.funchap.com/wp-content/uploads/2014/01/pictures-of-flowers.jpg


### how to run?

puma or ./run_development.bash

./run_production.bash


### about


@dux in 2014
About
----
Webpage and server that creates image mosaics from google search queries

Installation
----
Install [node.js](http://nodejs.org) and run:

```
cd server
npm install
```

Viewing the mosaic
----
Start the server with

```
cd server
npm start
```

and go to [localhost:8080](http://localhost:8080)

Custom Images / Webcam
----
To view the mosaic with a folder of your own images, place a **copy** of your folder (containing only images) in public/reup/ (eg public/reup/my_images/) and run `./util/rename.sh public/reup/my_images/`. Once the renamed images are in the correct directory, they can be viewed at [localhost:8080?staticFolder=my_images](http://localhost:8080?staticFolder=my_images).

To view the mosaic with the webcam, go to [localhost:8080?useCamera=true](http://localhost:8080?useCamera=true).

The camera and the static folder arguments can be concatenated with a '&'. Eg [localhost:8080?staticFolder=my_images&useCamera=true](http://localhost:8080?staticFolder=my_images&useCamera=true)

Libraries used
----
[three.js](https://github.com/mrdoob/three.js/)

[jquery](https://github.com/jquery/jquery)

proj.jpg by Klaus Friese (https://www.flickr.com/photos/hamburgerjung/13968044841/)

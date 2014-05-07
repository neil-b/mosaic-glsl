/*
  Since cross origin textures aren't allowed in html5 canvases without the
  texture provider's permission, this server, along with serving the contents
  in the public directory, downloads and hosts image urls it receives from
  the mosaic webpage.
*/

var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io').listen(server);
var fs = require('fs');

var request = require('request');
var mkdirp = require('mkdirp');

io.set('log level', 1);
server.listen(8080, '0.0.0.0');
app.use(express.static(__dirname + '/../public'));
app.use(express.static(__dirname + 'reup'));

function download(url, outPath, callback) {
  console.log('begin download', url);
  request.head(url, function(err, res, body) {
    if (!err && res.statusCode == 200) {
      var req = request(url).pipe(fs.createWriteStream(outPath));
      req.on('close', callback);
    }
  });
}

io.sockets.on('connection', function(socket) {
  console.log('user connected');
  socket.on('reuploadRequest', function(queries, urlStacks) {
    console.log('reupload requested');
    var remainingReuploads = 0;
    for (var i = 0; i < queries.length; i++) {
      remainingReuploads += urlStacks[i].length;
    }
    // TODO: what do we do if an image has a slow connection
    // TODO: don't download if file already exists
    var reuploadFolder = '../public/reup/';
    for (var i = 0; i < queries.length; i++) {
      for (var j = 0; j < urlStacks[i].length; j++) {
        (function(i, j) {
          mkdirp(reuploadFolder + queries[i] + '/', function(err) {
            if (err) {
              console.error(err);
            }
            else {
              download(urlStacks[i][j], reuploadFolder + queries[i] + '/' + j, function() {
                remainingReuploads--;
                console.log('image', urlStacks[i][j], 'downloaded', remainingReuploads, 'left');
                if (remainingReuploads == 0) {
                  console.log('all done');
                  socket.emit('reuploadComplete');
                }
              });
            }
          });
        })(i, j);
      }
    }
  });
});


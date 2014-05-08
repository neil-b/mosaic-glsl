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
  var TIMEOUT_MS = 10000; // abort after 10sec

  request.head(url, function(err, res, body) {
    try {
      if (!err && res.statusCode == 200) {
        var req = request({
          uri: url, 
          timeout: TIMEOUT_MS
        }).pipe(fs.createWriteStream(outPath));
        req.on('close', function() {
          callback(true);
        });
      }
      else {
        console.error(url, 'download failed (1)', err, res.statusCode);
        callback(false);
      }
    } catch (e) {
      console.error(url, 'download failed (2)', e);
      callback(false);
    }
  });
}

io.sockets.on('connection', function(socket) {
  console.log('user connected');
  socket.on('reuploadRequest', function(queries, urlStacks) {
    console.log('reupload requested');
    var remainingReuploads = 0;
    var successfulReuploads = [];
    for (var i = 0; i < queries.length; i++) {
      remainingReuploads += urlStacks[i].length;
      successfulReuploads.push([]);
    }

    function finish() {
      console.log('all done');
      socket.emit('reuploadComplete', successfulReuploads);
    }

    if (remainingReuploads == 0) {
      finish();
    }

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
              download(urlStacks[i][j], reuploadFolder + queries[i] + '/' + j, function(success) {
                remainingReuploads--;
                // keep track of all the images that were successfully reup-ed
                if (success) {
                  var goodReups = successfulReuploads[i];
                  if (!goodReups) goodReups = [];
                  goodReups.push(j);
                  successfulReuploads[i] = goodReups;
                }

                if (remainingReuploads == 0) {
                  finish();
                }
              });
            }
          });
        })(i, j);
      }
    }
  });
});


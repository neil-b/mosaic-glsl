/* Fragment shader */
precision highp float;
precision highp int;

// changes to these defines need to be reflected in the js code and vice versa
#define ATLAS_WIDTH 4096.0 // these two should be powers of two, for compat. with older gpus
#define ATLAS_HEIGHT 4096.0
#define ATLAS_SUB_WIDTH 512.0
#define ATLAS_SUB_HEIGHT 512.0
#define MAX_NUM_IMAGES (int((ATLAS_WIDTH * ATLAS_HEIGHT) / (ATLAS_SUB_WIDTH * ATLAS_SUB_HEIGHT)))

uniform float timePerLayer;
uniform float time; // in milliseconds
uniform vec2 resolution;
uniform vec2 mouse;

uniform int numSubImages;

uniform sampler2D superTileTexture;
uniform sampler2D subTileAtlas;

uniform sampler2D subTileAveragesTexture; // 1d texture

// returns the time in milliseconds the "layer" (eg the current level of recursion) has been active
float getLayerTime() {
  return mod(time, timePerLayer);
}

// returns the time in milliseconds the program has been running
float getTime() {
  return time;
}

// returns the amount of zoom to use
// 1.0 is no zoom 
float zoomFunc() {
  return 1.5 + sin(0.01*getTime()) * 0.5;
}

// returns the offset position of the camera
vec2 positionFunc() {
  return vec2(0.0, 0.0);
}

// Returns the texture coordinates of a tile (specified by index) from the texture atlas.
// tPos is the relative tile position (between (0, 0) and (1, 1))
vec2 getAtlasCoord(int index, vec2 tPos) {
  // this gets the starting _pixel_ of the correct tile in the mosaic
  vec2 atlasCoord = vec2(
    mod(float(index) * ATLAS_SUB_WIDTH, ATLAS_WIDTH),
    floor(float(index) * ATLAS_SUB_WIDTH / ATLAS_WIDTH) * ATLAS_SUB_HEIGHT
  );

  // this scales the correct starting pixel to the correct starting texture coord
  // we do some flipping on the y axis, since html5 canvas defines (0, 0) as the 
  // upper-left corner, while glsl defines (0, 0) as lower-left corner
  atlasCoord.x = atlasCoord.x / ATLAS_WIDTH;
  atlasCoord.y = 1. - (atlasCoord.y / ATLAS_HEIGHT);

  // apply the relative tile position to get the actual texture coordinate
  atlasCoord.x += tPos.x / 8.;
  atlasCoord.y -= (1. - tPos.y) / 8.;

  return atlasCoord;
}

void main() {
  const vec2 TILE_SIZE = vec2(0.02, 0.02); // adjust these for bigger tiles or "patches"
  vec2 nPos = gl_FragCoord.xy / resolution.xy; // coordinate of fragment from (0,0) to (1,1), wrt entire renderable area
  vec2 zPos = (vec2(nPos.x, nPos.y) + positionFunc()) / zoomFunc(); // coordinate of the fragment in the zoomed space

  vec2 tile = vec2(floor(zPos.x / TILE_SIZE.x), floor(zPos.y / TILE_SIZE.y)); // the tile this fragment resides in (eg (0,0), (1,4), etc...)
  vec2 tPos = zPos / TILE_SIZE - tile; // relative tile position (between (0, 0) and (1, 1))

  // calculate average color of the super image in the tile's region
  vec4 sum = vec4(0.);
  const int PIXEL_SAMPLES = 10;
  for (int i = 0; i < PIXEL_SAMPLES; i++) {
    for (int j = 0; j < PIXEL_SAMPLES; j++) {
      vec2 tileTopLeft = tile * TILE_SIZE;
      vec2 ijPercent = vec2(float(i) / float(PIXEL_SAMPLES), float(j) / float(PIXEL_SAMPLES));
      sum += texture2D(superTileTexture, tileTopLeft + ijPercent * TILE_SIZE);
    }
  }
  vec4 average = sum / float(PIXEL_SAMPLES * PIXEL_SAMPLES);

  // find the subtile texture with the closest average
  int closestIndex = -1;
  float closestDist = 9999999999.;
  for (int ti = 0; ti < MAX_NUM_IMAGES; ti++) {
    // for loops in glsl can't use non-const compares
    if (ti >= numSubImages) {
      break;
    }

    vec3 subTileAverage = texture2D(subTileAveragesTexture, 
                                    vec2(float(ti) / float(MAX_NUM_IMAGES), 0.)).rgb;
    float newDist = distance(average.rgb, subTileAverage);
    if (newDist < closestDist) {
      closestDist = newDist;
      closestIndex = ti;
    }
  }

  vec4 bigTilePixel = texture2D(superTileTexture, zPos);
  vec4 smallTilePixel = vec4(0.);

  vec2 atlasCoord = getAtlasCoord(closestIndex, tPos);
  smallTilePixel = texture2D(subTileAtlas, atlasCoord);
  smallTilePixel = mix(smallTilePixel, average, 0.5); // experimental: tint the pixel by the average color

  float mixFactor = getLayerTime() / timePerLayer; // how close this layer is to finishing
  gl_FragColor = mix(bigTilePixel, 
                     smallTilePixel,
                     smoothstep(-0.1, 1.1, mixFactor));

  // encode next supertile index in the bottommost row
  // the js code will read this to determine the next tile to "recursively" transition to
  if (gl_FragCoord.y == 0.5) {
    gl_FragColor = vec4(float(closestIndex) / float(numSubImages), 1., 1., 1.);
  }
}

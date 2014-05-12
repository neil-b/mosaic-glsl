#!/bin/bash

# prints the average color for every file in the supplied directory
# the output can be used by farthest_set.py to make a decent guess
# on the best subset that has the most diverse color range.
# this won't work correctly if non-image files are also in the directory

#requies ImageMagick
for f in $1/*;
do
  echo $f;
  convert $f -resize 1x1 txt: | awk -F '\(|\)' 'NR+1 % 2 {print $2}';
  echo '###';
done

"""
  Makes a decent guess on a subset of images that have the largest average
  pixel distance.
  A subset with a large average pixel distance results in a better looking
  mosaic on average.

  Input is a textfile supplied by average_color.sh
"""

import itertools
import math
import random
import os
import sys

if len(sys.argv) != 3:
  print 'usage: ./farthest_set.py infile outdir/'

f = open(sys.argv[1])
lines = f.readlines();
f.close();

fileColorDict = {}
fileName = None
average = None

# extract name and average color from infile
for line in lines:
  line = line.strip()
  if len(line) > 0: 
    if fileName == None:
      fileName = line
    elif average == None:
      average = [float(x) for x in line.split(',')]

    if line.startswith('###'):
      fileColorDict[fileName] = average
      fileName = None
      average = None


def dist(a, b):
  return math.sqrt((b[0] - a[0])**2 + (b[1] - a[1])**2 + (b[2] - a[2])**2)

def random_combination(iterable, r):
  "Random selection from itertools.combinations(iterable, r)"
  pool = tuple(iterable)
  n = len(pool)
  indices = sorted(random.sample(xrange(n), r))
  return tuple(pool[i] for i in indices)

# get largest subset distance
biggestDistance = -float('inf')
bestSubset = None
NUM_SAMPLES = 50000
for i in range(0, NUM_SAMPLES): 
  subset = random_combination(fileColorDict, 32)
  totalDistance = 0
  for name1 in subset:
    for name2 in subset:
      totalDistance += dist(fileColorDict[name1], fileColorDict[name2])
  if totalDistance > biggestDistance:
    biggestDistance = totalDistance
    bestSubset = subset

# copy subset into folder with mosaic naming convention
q = 0
for name in bestSubset:
  os.system('cp ' + name + ' ' + sys.argv[2] + '/' + str(q))
  q += 1

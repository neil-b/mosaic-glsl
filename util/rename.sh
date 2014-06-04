#!/bin/bash

# renames all files in the specified folder

if [ $# -ne 1 ]
then
  echo "Proper usage: ./rename.sh directory/"
  exit 1
fi

let n=0
for f in $1/*;
do
    mv "${f}" "${1}/${n}"; n=$((n+1)); 
done


#!/bin/bash

IN=$1
SEARCHTERM=$(sed 's/ By.*//' <<< $IN)

RESULT=$(/opt/calibre/calibredb --with-library=http://192.168.1.44:8765/#eBooks list --for-machine --search "Title:\"$SEARCHTERM\"")
SIZE=${#RESULT}

if [ $SIZE = 2 ]
then
  echo "Exit 0, no results"
#  echo "This search term resulted in EXIT CODE 0 " $SEARCHTERM >> log.txt
  exit 0
else
  echo "Exit 1, found results"
#  echo "This search term resulted in EXIT CODE 1 " $SEARCHTERM >> log.txt
  exit 1
fi

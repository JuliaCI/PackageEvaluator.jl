#!/bin/sh
# needs jq installed (https://stedolan.github.io/jq/download)
# usage: ./summary.sh 0.4*/*.json
for i in $(ls $1); do
  echo "$(basename $i) $(jq .status $i)"
done

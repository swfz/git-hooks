#!/bin/bash

awk '/console.log/ { match($0, /console.log/); print FILENAME ":" FNR ":" RSTART ":" $0 }' $@ \
  | reviewdog \
  -fail-level=any \
  -efm="%f:%l:%c:%m" \
  -diff='git diff --cached' \
  -reporter local


#!/bin/bash

grep -nH console.log $@ \
  | reviewdog \
  -fail-on-error \
  -efm="%f:%l: %m" \
  -diff='git diff --cached' \
  -reporter local


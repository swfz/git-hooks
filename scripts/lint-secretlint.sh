#!/bin/bash

# scripts以下に本スクリプトがある前提
script_dirname=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
top_dirname=$(cd "$script_dirname/.." && pwd)

${top_dirname}/node_modules/.bin/secretlint \
  --format checkstyle \
  --secretlintrc ${top_dirname}/.secretlintrc.json $@ \
  | reviewdog \
  -fail-level=any \
  -f checkstyle \
  -diff "git diff --cached" \
  -reporter local


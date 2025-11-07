#!/bin/bash

actionlint -format '{{range $err := .}}{{$err.Filepath}}:{{$err.Line}}:{{$err.Column}} {{$err.Kind}} {{$err.Message}}\n{{$err.Snippet}}\n\n{{end}}' $@ \
  | reviewdog \
  -fail-on-error \
  -efm="%f:%l:%c %m" \
  -diff='git diff --cached' \
  -reporter local


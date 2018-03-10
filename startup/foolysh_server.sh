#!/bin/bash

THIS=foolysh_server
WORKER=foolysh_worker.pl

if [[ $# < 1 ]]; then
  echo "Usage: $THIS <directory>"
  exit
fi

fswatch --version &>/dev/null
if [[ $? != 0 ]]; then
  echo "$THIS: fswatch is not installed"
  exit 1
fi

if [[ ! -d $1 ]]; then
  echo "$THIS: no such directory: $1"
  exit 1
fi

fswatch $FOOLYSH_FSWATCH_OPT -r $1 | xargs -n 1 perl -S $WORKER

# EOF

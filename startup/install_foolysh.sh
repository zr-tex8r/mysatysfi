#!/bin/bash

set -eu

export HOME=/home/vagrant
STARTUP_DIR=/vagrant/startup
BIN_DIR=~/bin

if [ -x $BIN_DIR/foolysh_server ]; then
  echo 'install_foolysh: nothing to do'
  exit
fi

mkdir $BIN_DIR || true
cp $STARTUP_DIR/foolysh_server.sh $BIN_DIR/foolysh_server
chmod +x $BIN_DIR/foolysh_server
cp $STARTUP_DIR/foolysh_worker.pl $BIN_DIR/foolysh_worker.pl

echo "export FOOLYSH_FSWATCH_OPT='-m poll_monitor'" >> ~/.profile

echo 'install_foolysh: done'

# EOF

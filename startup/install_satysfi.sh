#!/bin/bash

set -eu

export HOME=/home/vagrant
STARTUP_DIR=/vagrant/startup
BIN_DIR=~/bin

if [ -d ~/.satysfi ]; then
  echo 'install_satysfi: nothing to do'
  exit
fi

# initialize opam
opam init --auto-setup --comp=4.06.0
eval `opam config env`
opam update

# fetch source
git clone https://github.com/gfngfn/SATySFi.git
cd SATySFi
git submodule update --init --recursive

# build
opam pin add -y jbuilder 1.0+beta17
opam pin add -y satysfi .
opam install -y satysfi

# postprocess
PFX=`which satysfi`
ln -s ${PFX%/bin/satysfi}/share/satysfi ~/.satysfi
cp -p $STARTUP_DIR/*.ttf ~/.satysfi/dist/fonts/
chmod 644 ~/.satysfi/dist/fonts/*.ttf

# EOF

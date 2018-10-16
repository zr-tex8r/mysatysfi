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
opam init --auto-setup --comp=4.06.0 --disable-sandboxing
eval `opam env`
opam repository add satysfi-external https://github.com/gfngfn/satysfi-external-repo.git
opam update

# fetch source
git clone https://github.com/gfngfn/SATySFi.git
cd SATySFi
git submodule update --init --recursive

# build
opam pin add -y satysfi .
opam install -y satysfi

# postprocess
PFX=`which satysfi`
ln -s ${PFX%/bin/satysfi}/share/satysfi ~/.satysfi

# EOF

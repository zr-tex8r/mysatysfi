#!/bin/bash

set -eu

if which opam >/dev/null; then
  echo 'install_opam: nothing to do'
  exit
fi

wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh -O /tmp/install.sh
yes '' | sh /tmp/install.sh
rm -f /tmp/install.sh

# EOF

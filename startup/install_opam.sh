#!/bin/bash

set -eu

if which opam >/dev/null; then
  echo 'install_opam: nothing to do'
  exit
fi

wget https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh -O /tmp/opam_installer.sh
sh /tmp/opam_installer.sh /usr/local/bin
rm -f /tmp/opam_installer.sh

# EOF

#!/bin/bash

DONE='.~setup-done'

if [ -f $DONE ]; then
  echo "Already setup"
  exit 0
fi

set -eu -o pipefail

# Install asdf
# https://asdf-vm.com/guide/getting-started.html
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
ln tool-versions "${HOME}/.tool-versions"

touch $DONE


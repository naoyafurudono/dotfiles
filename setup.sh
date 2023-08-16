#!/bin/bash

DONE='.~setup-done'


if [ -f $DONE ]; then
  echo "Already setup"
  exit 0
fi

set -eu -o pipefail

# branch by the os
case "$(uname)" in
  Darwin)
    # Install Homebrew
    # https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    brew install fish nvim bat fzf ripgrep fd
    ;;
  Linux)
    sudo apt-get update -y
    sudo apt-get install -y fish neovim bat fzf ripgrep fd-find
    ;;
  *)
    echo "Unknown OS"
    exit 1
    ;;
esac

# Install asdf
# https://asdf-vm.com/guide/getting-started.html
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0

ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
ln tool-versions "${HOME}/.tool-versions"

touch $DONE

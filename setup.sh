#!/bin/bash

which git > /dev/null || (echo "git is not installed" >&2 && exit 1)
set -eu -o pipefail

function init() {
  cd "$(dirname "$0")"
  git submodule update --init --recursive

  cp -rf "dotfiles" "$HOME/.config"
  cd "$HOME/.config"
}

function get_common () {
  # branch by the os
  case "$(uname)" in
  Darwin)
    # Install Homebrew
    # https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    brew install \
      fish \
      nvim \
      fzf \
      htop \
    ;;
  Linux)
    set +e
    apt-get update && apt-get install -y sudo
    set -e
    sudo apt-get update
    sudo apt-get install -y \
      build-essential \
      fish \
      neovim \
      fzf \
      curl \
      htop \
    ;;
  *)
    echo "Unknown OS" >&2
    exit 1
    ;;
  esac \
}

function get_rust() {curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  cargo install --locked \
    exa \
    bat \
    fd-find \
    ripgrep \
    zoxide \ 
}

# Install asdf
# https://asdf-vm.com/guide/getting-started.html

function get_asdf() {
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
  ln -s ~/.asdf/completions/asdf.fish fish/completions
  touch tool-versions
  ln tool-versions "${HOME}/.tool-versions"
}

init()
get_common()&
get_rust()&
get_asdf()&

wait

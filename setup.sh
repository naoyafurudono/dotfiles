#!/bin/bash

which git > /dev/null || (echo "git is not installed" >&2 && exit 1)
set -eu -o pipefail

function init() {
  cp -rf "dotfiles" "$HOME/.config"
  cd "$HOME/.config"

}

function get_essentials () {
  # branch by the os
  case "$(uname)" in
  Darwin)
    ;;
  Linux)
    set +e
    apt-get update && apt-get install -y sudo
    set -e
    sudo apt-get update
    sudo apt-get install -y \
      build-essential \
      curl \
    ;;
  *)
    echo "Unknown OS" >&2
    exit 1
    ;;
  esac \

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
      direnv \
      jq \
      yq \
      ghostty \
      typos-cli \
    ;;
  Linux)
    set +e
    apt-get -qq update && apt-get -qq install -y sudo
    set -e
    sudo apt-get -qq update
    sudo apt-get -qq install -y \
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

function get_rust() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  cargo install --locked \
    bat \
    easy-cp \
    eza \
    fd-find \
    install-update \
    mise \
    ripgrep \
    zoxide

}

function get_go() {
    mise install go
    go install hugo
}

function setup() {
    ln -s ~/.config/tmux/tmux.conf ~.tmux.conf
    case "$(uname)" in
    Darwin)
      defaults delete com.apple.dock persistent-apps
    ;;
    esac
}

init ;
get_essentials ;
get_common & \
get_rust; get_go & \
setup \
wait


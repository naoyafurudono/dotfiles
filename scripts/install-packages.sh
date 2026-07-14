#!/bin/sh
# shellcheck disable=SC2312

# OS パッケージを宣言ファイルから導入する。
# macOS: config/dotfiles/Brewfile, Debian 系 Linux: config/dotfiles/packages-debian.txt

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

case "$(uname -s)" in
Darwin)
    if ! command -v brew >/dev/null 2>&1; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    brew bundle --file="${repo_root}/config/dotfiles/Brewfile"
    ;;
Linux)
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "Only Debian-based Linux distributions are currently supported" >&2
        exit 1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        sudo_cmd=""
    elif command -v sudo >/dev/null 2>&1; then
        sudo_cmd="sudo"
    else
        echo "sudo is required to install system packages" >&2
        exit 1
    fi

    ${sudo_cmd} apt-get update
    # The manifest contains one package name per line and no shell syntax.
    # shellcheck disable=SC2046
    ${sudo_cmd} apt-get install -y $(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "${repo_root}/config/dotfiles/packages-debian.txt")
    ;;
*)
    echo "System package installation is not supported on $(uname -s)" >&2
    exit 1
    ;;
esac

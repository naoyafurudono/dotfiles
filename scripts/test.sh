#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

destination="$test_root/home"
config="$test_root/chezmoi.toml"
mkdir -p "$destination"

chezmoi \
    --config "$config" \
    --source "$repo_root/home" \
    --destination "$destination" \
    init --promptString 'Machine type (personal/work/server)=personal'

chezmoi \
    --config "$config" \
    --source "$repo_root/home" \
    --destination "$destination" \
    apply --exclude=scripts

test -f "$destination/.config/fish/config.fish"
test -f "$destination/.config/mise/config.toml"
test -x "$destination/.config/git/credential-helper.sh"
test -L "$destination/.claude"
test "$(readlink "$destination/.claude")" = ".config/claude"
test ! -e "$destination/.config/fish/fish_variables"

chezmoi \
    --config "$config" \
    --source "$repo_root/home" \
    --destination "$destination" \
    verify --exclude=scripts

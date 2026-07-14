#!/bin/sh

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

# 主要ファイルの存在と権限
test -f "${repo_root}/config/fish/config.fish"
test -f "${repo_root}/config/mise/config.toml"
test -x "${repo_root}/config/git/credential-helper.sh"
test -x "${repo_root}/scripts/install-packages.sh"
test -f "${repo_root}/templates/ghostty-config.tmpl"
test -f "${repo_root}/templates/com.naoyafurudono.improve-session-recall.plist.tmpl"

# 動的ファイル・秘密情報がソースに紛れ込んでいないこと
test ! -e "${repo_root}/config/fish/fish_variables"
test ! -e "${repo_root}/config/gh/hosts.yml"
test ! -e "${repo_root}/config/claude/settings.local.json"

# [dotfiles] 設定が parse でき、マッピングが解決できること
MISE_GLOBAL_CONFIG_FILE="${repo_root}/config/mise/config.toml" \
    mise dotfiles status >/dev/null

# dry-run が成功すること（実 HOME には書き込まない）
MISE_GLOBAL_CONFIG_FILE="${repo_root}/config/mise/config.toml" \
    mise dotfiles apply --dry-run >/dev/null

echo "ok"

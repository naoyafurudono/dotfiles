#!/bin/bash
#
# main/master ブランチ保護の共通ロジック
#
# 使い方:
#   source "$(dirname "$0")/lib/protect-branch.sh"
#   check_branch_protection "commit" "$ALLOW_MAIN_COMMIT"
#   check_push_protection "$ALLOW_MAIN_PUSH"
#

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
WHITELIST_FILE="${SCRIPT_DIR}/whitelist.txt"
REMOTE_URL="$(git config remote.origin.url 2>/dev/null || echo "")"

# whitelist にリモートURLが含まれているかチェック
is_whitelisted() {
  [[ -n "$REMOTE_URL" ]] && grep -Fxq "$REMOTE_URL" "$WHITELIST_FILE" 2>/dev/null
}

# 現在のブランチが main/master かチェック
is_protected_branch() {
  local branch="$1"
  [[ "$branch" = "main" || "$branch" = "master" ]]
}

# pre-commit 用: 現在のブランチをチェック
check_branch_protection() {
  local action="$1"
  local allow_env="$2"

  # 環境変数でバイパス
  if [[ "$allow_env" = "1" ]]; then
    return 0
  fi

  # whitelist チェック
  if is_whitelisted; then
    return 0
  fi

  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if is_protected_branch "$current_branch"; then
    echo "Do not ${action} directly to ${current_branch} branch!" 1>&2
    echo "Use ALLOW_MAIN_${action^^}=1 git ${action} to bypass." 1>&2
    exit 1
  fi
}

# pre-push 用: push 先のブランチをチェック
check_push_protection() {
  local allow_env="$1"

  # 環境変数でバイパス
  if [[ "$allow_env" = "1" ]]; then
    return 0
  fi

  # whitelist チェック
  if is_whitelisted; then
    return 0
  fi

  while read local_ref local_sha1 remote_ref remote_sha1; do
    local branch_name="${remote_ref#refs/heads/}"
    if is_protected_branch "$branch_name"; then
      echo "Do not push to ${branch_name} branch!" 1>&2
      echo "Remote URL: $REMOTE_URL" 1>&2
      echo "Use ALLOW_MAIN_PUSH=1 git push to bypass." 1>&2
      exit 1
    fi
  done
}

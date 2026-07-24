#!/bin/bash
# colorme org の Issue/PR をチームタスクボード (project 123) に登録する。
# 登録 (item-add) + Status 設定 + assignee (donokun) 設定までを一括で行う。
#
# 使い方:
#   colorme-board-register.sh <Issue/PR URL> [status]   # 手動実行
#   (引数なし)                                          # Claude Code PostToolUse(Bash) hook として stdin JSON を読む
#
# status: backlog / ready / in-progress / in-review / done
#         省略時: Issue=backlog, PR=in-progress

set -uo pipefail

export GH_HOST=git.pepabo.com
PROJECT_NUMBER=123
PROJECT_OWNER=colorme
# 以下の ID は project 123 で固定（gh project view/field-list で取得済み）
PROJECT_ID="MDk6UHJvamVjdFYyMzQ5"
STATUS_FIELD_ID="MDI2OlByb2plY3RWMlNpbmdsZVNlbGVjdEZpZWxkNDkzNw=="
ASSIGNEE=donokun

status_option_id() {
  case "$1" in
    backlog) echo f75ad846 ;;
    ready) echo 50380717 ;;
    in-progress) echo 47fc9ee4 ;;
    in-review) echo c39c9d61 ;;
    done) echo 98236657 ;;
    *) return 1 ;;
  esac
}

register() {
  local url=$1 status=${2:-} kind opt_id item_id
  case "$url" in
    */pull/*) kind=pr; : "${status:=in-progress}" ;;
    */issues/*) kind=issue; : "${status:=backlog}" ;;
    *) echo "unsupported URL: $url" >&2; return 1 ;;
  esac
  opt_id=$(status_option_id "$status") || { echo "unknown status: $status" >&2; return 1; }

  item_id=$(gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$url" --format json | jq -r .id)
  if [ -z "$item_id" ] || [ "$item_id" = null ]; then
    echo "gh project item-add failed for $url" >&2
    return 1
  fi

  gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" \
    --field-id "$STATUS_FIELD_ID" --single-select-option-id "$opt_id" >/dev/null || return 1

  if [ "$kind" = pr ]; then
    gh pr edit "$url" --add-assignee "$ASSIGNEE" >/dev/null || return 1
  else
    gh issue edit "$url" --add-assignee "$ASSIGNEE" >/dev/null || return 1
  fi
  echo "registered: $url (status=$status, assignee=$ASSIGNEE)"
}

# 引数ありなら手動実行モード
if [ $# -ge 1 ]; then
  register "$@"
  exit $?
fi

# hook モード: gh issue/pr create の実行結果 (stdout) から作成された URL を拾って登録する
input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
grep -qE 'gh (issue|pr) create' <<<"$cmd" || exit 0
out=$(jq -r '.tool_response.stdout // ""' <<<"$input")
# 作成 URL は stdout の末尾に出るので最後のマッチを採る。
# tool_input (issue 本文の親 issue URL 等) からは拾わないこと。
url=$(grep -oE 'https://git\.pepabo\.com/colorme/[^/[:space:]]+/(pull|issues)/[0-9]+' <<<"$out" | tail -1)
[ -n "$url" ] || exit 0

if msg=$(register "$url" 2>&1); then
  jq -n --arg m "$msg" '{
    systemMessage: ("colorme board hook: " + $m),
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("チームタスクボード(colorme project 123)への登録・Status設定・assignee(donokun)設定は hook が自動実行済み: " + $m + " — 追加の gh project / assignee 操作は不要。Status を変えたい場合のみ ~/.config/claude/hooks/colorme-board-register.sh <URL> <status> を実行する。")
    }
  }'
else
  jq -n --arg m "$msg" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("colorme board hook が失敗した: " + $m + " — ~/.config/claude/hooks/colorme-board-register.sh <URL> [status] で手動登録すること。")
    }
  }'
fi
exit 0

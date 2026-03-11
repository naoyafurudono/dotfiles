#!/bin/bash
# Claude Code の SessionStart / SessionEnd hook から呼ばれ、
# tmux ペインとセッションIDの対応を管理する。
#
# SessionStart: ペインとセッションIDの対応を記録
# SessionEnd:   ペインのエントリを削除
#
# stdin: Claude Code hook の JSON (session_id, hook_event_name を含む)
# 環境変数: TMUX_PANE (tmux ペインID)

set -eu -o pipefail

MAPPING_DIR="${HOME}/.tmux/resurrect"
MAPPING_FILE="${MAPPING_DIR}/claude-sessions.txt"

# tmux 外で実行された場合は何もしない
if [[ -z "${TMUX_PANE:-}" ]]; then
  exit 0
fi

input="$(cat)"
hook_event="$(echo "${input}" | jq -r '.hook_event_name // empty')"
session_id="$(echo "${input}" | jq -r '.session_id // empty')"

if [[ -z "${session_id}" ]]; then
  exit 0
fi

# セッション名:ウィンドウ番号.ペイン番号 を取得
pane_target="$(tmux display-message -p -t "${TMUX_PANE}" '#{session_name}:#{window_index}.#{pane_index}')"

mkdir -p "${MAPPING_DIR}"

# 既存エントリを除去
if [[ -f "${MAPPING_FILE}" ]]; then
  grep -v "^${pane_target}	" "${MAPPING_FILE}" > "${MAPPING_FILE}.tmp" || true
  mv "${MAPPING_FILE}.tmp" "${MAPPING_FILE}"
fi

# SessionStart なら新しいエントリを追加、SessionEnd なら削除のみ
if [[ "${hook_event}" != "SessionEnd" ]]; then
  printf '%s\t%s\n' "${pane_target}" "${session_id}" >> "${MAPPING_FILE}"
fi

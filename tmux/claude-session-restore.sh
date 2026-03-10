#!/bin/bash
# tmux-resurrect の post-restore-all フックから呼ばれ、
# Claude Code が動いていたペインでセッションを再開する。
#
# resurrect が復元したペインのうち、claude-sessions.txt に
# 記録されているものに対して claude --resume <session_id> を送信する。

set -eu -o pipefail

MAPPING_FILE="${HOME}/.tmux/resurrect/claude-sessions.txt"

if [[ ! -f "${MAPPING_FILE}" ]]; then
  exit 0
fi

while IFS=$'\t' read -r pane_target session_id; do
  # ペインが存在するか確認
  if tmux has-session -t "${pane_target}" 2>/dev/null; then
    # ペインに claude --resume コマンドを送信
    tmux send-keys -t "${pane_target}" "claude --resume ${session_id}" Enter
  fi
done < "${MAPPING_FILE}"

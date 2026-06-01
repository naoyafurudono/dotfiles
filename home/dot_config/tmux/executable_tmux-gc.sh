#!/bin/bash
# 未アタッチかつ Claude Code が動いていない tmux セッションを掃除する（GC）。
#
# 残す条件（いずれかを満たすセッションは kill しない）:
#   - attached==1 … 誰かがアタッチ中
#   - いずれかのペインの pane_current_command が *.*.* に一致 … Claude Code 稼働中
#     （Claude Code は argv[0] にバージョン文字列 例:2.1.121 を書くため。tmux.conf の z バインドと同じ判別手法）
#
# 想定する呼ばれ方:
#   - tmux の client-detached フックから run-shell -b で自動発火（離脱時に掃除）
#   - 手動実行（引数なしで kill、`-n` で dry-run、`-v` でログを stderr にも出す）
#
# ログ: ~/.cache/tmux-gc.log に追記する。

set -u -o pipefail

LOG="${HOME}/.cache/tmux-gc.log"
mkdir -p "$(dirname "${LOG}")"

DRY_RUN=0
VERBOSE=0
for arg in "$@"; do
  case "${arg}" in
    -n|--dry-run) DRY_RUN=1 ;;
    -v|--verbose) VERBOSE=1 ;;
  esac
done

log() {
  local msg="$1"
  printf '%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${msg}" >>"${LOG}"
  if [[ "${VERBOSE}" -eq 1 ]]; then
    printf '%s\n' "${msg}" >&2
  fi
}

# セッションが「残すべき」かを判定する。
#   $1: セッション名
#   $2: attached (0/1)
# 戻り値: 0=残す, 1=GC対象
keep_session() {
  local name="$1" attached="$2"
  # main は母艦セッション。Ghostty クラッシュ時に全クライアントが落ちて
  # 一時的に未アタッチになっても消さず、再起動時の自動再接続先として常に残す。
  if [[ "${name}" == "main" ]]; then
    return 0
  fi
  if [[ "${attached}" != "0" ]]; then
    return 0
  fi
  # ペインのコマンドに *.*.*（Claude Code のバージョン文字列）があるか
  local cmd
  while IFS= read -r cmd; do
    case "${cmd}" in
      *.*.*) return 0 ;;
    esac
  done < <(tmux list-panes -t "${name}" -F '#{pane_current_command}' 2>/dev/null)
  return 1
}

killed=0
kept=0

while IFS=$'\t' read -r name attached; do
  [[ -z "${name}" ]] && continue
  if keep_session "${name}" "${attached}"; then
    kept=$((kept + 1))
    continue
  fi
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "would-kill ${name}"
  else
    tmux kill-session -t "${name}" 2>/dev/null && log "killed ${name}"
  fi
  killed=$((killed + 1))
done < <(tmux list-sessions -F "#{session_name}$(printf '\t')#{session_attached}" 2>/dev/null)

log "summary kept=${kept} killed=${killed} dry_run=${DRY_RUN}"

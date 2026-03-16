#!/bin/bash
input=$(cat)

# === データ取得 ===
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
VIM_MODE=$(echo "$input" | jq -r '.vim.mode // empty')

# === カラー定義 (Atom One Light パレット) ===
BLUE='\033[38;2;64;120;242m'    # #4078f2
GREEN='\033[38;2;80;161;79m'    # #50a14f
ORANGE='\033[38;2;193;132;1m'   # #c18401
RED='\033[38;2;228;86;73m'      # #e45649
PURPLE='\033[38;2;166;38;164m'  # #a626a4
CYAN='\033[38;2;1;132;188m'     # #0184bc
DIM='\033[38;2;160;160;160m'    # dimmed text
RESET='\033[0m'

# === プログレスバー (グラデーション) ===
BAR_WIDTH=15
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

# 使用率に応じた色
if [ "$PCT" -ge 90 ]; then
  BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then
  BAR_COLOR="$ORANGE"
elif [ "$PCT" -ge 40 ]; then
  BAR_COLOR="$CYAN"
else
  BAR_COLOR="$GREEN"
fi

BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}━"; done
for ((i=0; i<EMPTY; i++)); do BAR="${BAR}╌"; done

# === 時間フォーマット ===
DURATION_SEC=$((DURATION_MS / 1000))
MINS=$((DURATION_SEC / 60))
SECS=$((DURATION_SEC % 60))

# === コストフォーマット ===
COST_FMT=$(printf '%.2f' "$COST")

# === Vim モード表示 ===
MODE_STR=""
if [ -n "$VIM_MODE" ]; then
  if [ "$VIM_MODE" = "NORMAL" ]; then
    MODE_STR="${BLUE} N ${RESET}"
  else
    MODE_STR="${GREEN} I ${RESET}"
  fi
fi

# === 変更行数 ===
CHANGES=""
if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ]; then
  CHANGES=" ${DIM}│${RESET} ${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
fi

# === 出力 ===
echo -e "${MODE_STR}${PURPLE}◆${RESET} ${DIM}${MODEL}${RESET}  ${BAR_COLOR}${BAR}${RESET} ${DIM}${PCT}%${RESET}  ${ORANGE}\$${COST_FMT}${RESET}  ${CYAN}${MINS}m${SECS}s${RESET}${CHANGES}"

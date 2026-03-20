#!/bin/bash
input=$(cat)

# === データ取得 ===
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // empty')
AGENT=$(echo "$input" | jq -r '.agent.name // empty')

# === カラー定義 (Atom One Light パレット) ===
BLUE='\033[38;2;64;120;242m'    # #4078f2
GREEN='\033[38;2;80;161;79m'    # #50a14f
ORANGE='\033[38;2;193;132;1m'   # #c18401
RED='\033[38;2;228;86;73m'      # #e45649
PURPLE='\033[38;2;166;38;164m'  # #a626a4
CYAN='\033[38;2;1;132;188m'     # #0184bc
DIM='\033[38;2;160;160;160m'    # dimmed text
LIGHT_PURPLE='\033[38;2;200;120;200m'  # パープル明るめ
RESET='\033[0m'

# === ◆ アイコン (コンテキスト使用率で3段階に色変化) ===
# 余裕あり: パープル(通常) → 注意: 明るいパープル → 危険: 赤
if [ "$PCT" -ge 80 ]; then
  DIAMOND="${RED}◆${RESET}"
elif [ "$PCT" -ge 50 ]; then
  DIAMOND="${LIGHT_PURPLE}◆${RESET}"
else
  DIAMOND="${PURPLE}◆${RESET}"
fi

# === セッション ID (完全表示) ===
SHORT_SESSION=""
if [ -n "$SESSION_ID" ]; then
  SHORT_SESSION="${DIM}${SESSION_ID}${RESET}"
fi

# === ディレクトリ (末尾のディレクトリ名のみ) ===
DIR_STR=""
if [ -n "$CWD" ]; then
  DIR_NAME="${CWD##*/}"
  DIR_STR="${DIR_NAME}"
fi

# === エージェント名 (アイコン付き) ===
AGENT_ICONS=("⬡" "◎" "✦" "⏣" "◈" "❖" "⬢" "◉" "★" "⟐")
AGENT_STR=""
if [ -n "$AGENT" ]; then
  HASH=0
  for ((i=0; i<${#AGENT}; i++)); do
    CHAR_VAL=$(printf '%d' "'${AGENT:$i:1}")
    HASH=$(( (HASH + CHAR_VAL) % ${#AGENT_ICONS[@]} ))
  done
  ICON="${AGENT_ICONS[$HASH]}"
  AGENT_STR=" ${DIM}│${RESET} ${PURPLE}${ICON} ${AGENT}${RESET}"
fi

# === プログレスバー ===
BAR_WIDTH=12
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

if [ "$PCT" -ge 80 ]; then
  BAR_COLOR="$RED"
elif [ "$PCT" -ge 50 ]; then
  BAR_COLOR="$LIGHT_PURPLE"
else
  BAR_COLOR="$PURPLE"
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

# === 変更行数 ===
CHANGES=""
if [ "$ADDED" -gt 0 ] || [ "$REMOVED" -gt 0 ]; then
  CHANGES=" ${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
fi

# === 出力 (2行) ===
echo -e "${DIAMOND} ${DIR_STR}  ${SHORT_SESSION}${AGENT_STR}"
echo -e "  ${DIM}${MODEL}${RESET} ${BAR_COLOR}${BAR}${RESET} ${DIM}${PCT}%${RESET}  ${ORANGE}\$${COST_FMT}${RESET}  ${CYAN}${MINS}m${SECS}s${RESET}${CHANGES}"

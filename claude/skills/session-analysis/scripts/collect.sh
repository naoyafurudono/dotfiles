#!/bin/bash
# セッションログを分析するスクリプト
# 使い方:
#   collect.sh list [日付指定]    - セッション一覧
#   collect.sh search [キーワード...] - キーワード検索
#
# 日付指定: today(デフォルト), yesterday, YYYY-MM-DD, YYYY-MM-DD..YYYY-MM-DD, 7d
# subagents は除外（メインセッションのみ）

SESSIONS_DIR="$HOME/.claude/projects"
TMPOUT=$(mktemp)
trap 'rm -f "$TMPOUT"' EXIT

# OS検出
if [[ "$(uname)" == "Darwin" ]]; then
  IS_MACOS=true
else
  IS_MACOS=false
fi

# --- 日付ユーティリティ ---

date_today() { date +%Y-%m-%d; }

date_yesterday() {
  if $IS_MACOS; then
    date -v-1d +%Y-%m-%d
  else
    date -d "yesterday" +%Y-%m-%d
  fi
}

date_add_days() {
  local base_date="$1" days="$2"
  if $IS_MACOS; then
    date -j -v"${days}d" -f "%Y-%m-%d" "$base_date" +%Y-%m-%d 2>/dev/null || echo "$base_date"
  else
    date -d "$base_date ${days} days" +%Y-%m-%d 2>/dev/null || echo "$base_date"
  fi
}

get_file_mtime() {
  if $IS_MACOS; then
    stat -f "%Sm" -t "%Y-%m-%d" "$1" 2>/dev/null
  else
    stat -c "%y" "$1" 2>/dev/null | cut -d' ' -f1
  fi
}

parse_timestamp_to_date() {
  local timestamp="$1"
  if $IS_MACOS; then
    local utc_datetime="${timestamp%.*}+0000"
    date -j -f "%Y-%m-%dT%H:%M:%S%z" "$utc_datetime" "+%Y-%m-%d" 2>/dev/null
  else
    date -d "$timestamp" "+%Y-%m-%d" 2>/dev/null
  fi
}

# 日付を比較 (date1 <= date2)
date_le() {
  [[ "$1" < "$2" || "$1" == "$2" ]]
}

# セッション情報を出力するヘルパー
print_session_header() {
  local filepath="$1" extra_info="$2"
  local project first_user_line cwd branch

  project=$(echo "$filepath" | sed "s|.*projects/||" | cut -d'/' -f1)
  first_user_line=$(grep -m1 '"type":"user"' "$filepath" 2>/dev/null)
  cwd=$(echo "$first_user_line" | jq -r '.cwd // "unknown"' 2>/dev/null)
  branch=$(echo "$first_user_line" | jq -r '.gitBranch // ""' 2>/dev/null)

  echo "## $project${extra_info:+ ($extra_info)}"
  echo "- 作業ディレクトリ: $cwd"
  [ -n "$branch" ] && [ "$branch" != "null" ] && echo "- ブランチ: $branch"
  echo ""
}

# --- list モード ---

list_sessions() {
  local date_spec="${1:-today}"
  local start_date end_date

  case "$date_spec" in
    today)
      start_date=$(date_today)
      end_date="$start_date"
      ;;
    yesterday)
      start_date=$(date_yesterday)
      end_date="$start_date"
      ;;
    *..*)
      start_date="${date_spec%..*}"
      end_date="${date_spec#*..}"
      ;;
    *d)
      local days="${date_spec%d}"
      end_date=$(date_today)
      start_date=$(date_add_days "$end_date" "-$days")
      ;;
    *)
      start_date="$date_spec"
      end_date="$date_spec"
      ;;
  esac

  echo "# セッション一覧: $start_date ~ $end_date"
  echo ""

  # mtime フィルタ用の前後日
  local mtime_start mtime_end
  mtime_start=$(date_add_days "$start_date" -1)
  mtime_end=$(date_add_days "$end_date" +1)

  find "$SESSIONS_DIR" -name "*.jsonl" -type f -not -path "*/subagents/*" 2>/dev/null | while read -r filepath; do
    # mtime 事前フィルタ
    local file_mtime
    file_mtime=$(get_file_mtime "$filepath") || continue
    if ! (date_le "$mtime_start" "$file_mtime" && date_le "$file_mtime" "$mtime_end"); then
      continue
    fi

    # timestamp 正確フィルタ
    local first_timestamp
    first_timestamp=$(grep -m1 '"type":"user"' "$filepath" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null) || true
    [ -z "$first_timestamp" ] || [ "$first_timestamp" = "null" ] && continue

    local session_date
    session_date=$(parse_timestamp_to_date "$first_timestamp") || continue

    if date_le "$start_date" "$session_date" && date_le "$session_date" "$end_date"; then
      print_session_header "$filepath" "$session_date"
      echo "### 最初のユーザーメッセージ"

      grep '"type":"user"' "$filepath" 2>/dev/null | head -3 | jq -r '
        if .message.content | type == "string" then
          .message.content | split("\n")[0][:150]
        else
          ((.message.content[] | select(.type == "text") | .text | split("\n")[0][:150]) // "")
        end
      ' 2>/dev/null | grep -v '^$' | sed 's/^/- /' || true

      echo ""
    fi
  done > "$TMPOUT"

  if [ -s "$TMPOUT" ]; then
    head -n 500 "$TMPOUT"
  else
    echo "(該当するセッションはありませんでした)"
  fi
}

# --- search モード ---

search_sessions() {
  local keywords=("$@")

  if [ ${#keywords[@]} -eq 0 ]; then
    echo "エラー: 検索キーワードを指定してください"
    exit 1
  fi

  echo "# セッション検索: ${keywords[*]}"
  echo ""

  # 最初のキーワードで grep、残りで絞り込み
  local first_kw="${keywords[0]}"
  local matched_files
  matched_files=$(grep -ril "$first_kw" "$SESSIONS_DIR" --include="*.jsonl" 2>/dev/null | grep -v '/subagents/' || true)

  # 追加キーワードで AND フィルタ
  local kw
  for kw in "${keywords[@]:1}"; do
    matched_files=$(echo "$matched_files" | while read -r f; do
      [ -n "$f" ] && grep -qil "$kw" "$f" 2>/dev/null && echo "$f"
    done || true)
  done

  echo "$matched_files" | while read -r filepath; do
    [ -z "$filepath" ] && continue

    local first_timestamp session_date
    first_timestamp=$(grep -m1 '"type":"user"' "$filepath" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null) || true
    if [ -n "$first_timestamp" ] && [ "$first_timestamp" != "null" ]; then
      session_date=$(parse_timestamp_to_date "$first_timestamp") || session_date="unknown"
    else
      session_date="unknown"
    fi

    print_session_header "$filepath" "$session_date"

    # マッチ行のコンテキストを表示
    echo "### マッチした内容"
    local kw
    for kw in "${keywords[@]}"; do
      grep -i "$kw" "$filepath" 2>/dev/null | head -5 | jq -r '
        if .message then
          if .message.content | type == "string" then
            .message.content | split("\n")[0][:150]
          else
            ((.message.content[]? | select(.type == "text") | .text | split("\n")[0][:150]) // "")
          end
        elif .content then
          if .content | type == "string" then
            .content | split("\n")[0][:150]
          else
            ((.content[]? | select(.type == "text") | .text | split("\n")[0][:150]) // "")
          end
        else
          empty
        end
      ' 2>/dev/null | grep -v '^$' | sed 's/^/- /' || true
    done

    echo ""
  done > "$TMPOUT"

  if [ -s "$TMPOUT" ]; then
    head -n 500 "$TMPOUT"
  else
    echo "(該当するセッションはありませんでした)"
  fi
}

# --- メインエントリポイント ---

mode="${1:-list}"
shift 2>/dev/null || true

case "$mode" in
  list)   list_sessions "$@" ;;
  search) search_sessions "$@" ;;
  *)
    # mode が list/search 以外の場合、キーワードとみなして search にフォールバック
    search_sessions "$mode" "$@"
    ;;
esac

#!/bin/bash
# セッションログを分析するスクリプト
# 使い方:
#   collect.sh list [日付指定]    - セッション一覧
#   collect.sh search [キーワード...] - キーワード検索
#
# 日付指定: today(デフォルト), yesterday, YYYY-MM-DD, YYYY-MM-DD..YYYY-MM-DD, 7d
# subagents は除外（メインセッションのみ）

SESSIONS_DIR="$HOME/.claude/projects"
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# 並列度 (CPUコア数、取得失敗時は8)
NPROC=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 8)

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

  local mtime_start mtime_end
  mtime_start=$(date_add_days "$start_date" -1)
  mtime_end=$(date_add_days "$end_date" +1)

  local results_dir="$TMPDIR_WORK/list_results"
  mkdir -p "$results_dir"

  # ワーカースクリプトを一度だけ書き出す
  cat > "$TMPDIR_WORK/list_worker.sh" << 'WORKER_EOF'
#!/bin/bash
start_date="$1" end_date="$2" mtime_start="$3" mtime_end="$4" results_dir="$5" is_macos="$6"
shift 6

for filepath in "$@"; do
  # mtime 事前フィルタ
  if [[ "$is_macos" == "true" ]]; then
    file_mtime=$(stat -f "%Sm" -t "%Y-%m-%d" "$filepath" 2>/dev/null) || continue
  else
    file_mtime=$(stat -c "%y" "$filepath" 2>/dev/null | cut -d' ' -f1) || continue
  fi
  if ! { [[ "$mtime_start" < "$file_mtime" || "$mtime_start" == "$file_mtime" ]] && \
         [[ "$file_mtime" < "$mtime_end" || "$file_mtime" == "$mtime_end" ]]; }; then
    continue
  fi

  # 1回の grep + jq でセッション情報取得
  first_user_line=$(grep -m1 '"type":"user"' "$filepath" 2>/dev/null) || continue
  [ -z "$first_user_line" ] && continue

  session_info=$(echo "$first_user_line" | jq -r '[.timestamp // "", .cwd // "unknown", .gitBranch // ""] | @tsv' 2>/dev/null) || continue
  IFS=$'\t' read -r timestamp cwd branch <<< "$session_info"
  [ -z "$timestamp" ] && continue

  # timestamp → 日付
  if [[ "$is_macos" == "true" ]]; then
    utc_datetime="${timestamp%.*}+0000"
    session_date=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$utc_datetime" "+%Y-%m-%d" 2>/dev/null) || continue
  else
    session_date=$(date -d "$timestamp" "+%Y-%m-%d" 2>/dev/null) || continue
  fi

  # 日付範囲チェック
  if ! { [[ "$start_date" < "$session_date" || "$start_date" == "$session_date" ]] && \
         [[ "$session_date" < "$end_date" || "$session_date" == "$end_date" ]]; }; then
    continue
  fi

  project=$(echo "$filepath" | sed "s|.*projects/||" | cut -d'/' -f1)

  user_msgs=$(grep '"type":"user"' "$filepath" 2>/dev/null | head -3 | jq -r '
    if .message.content | type == "string" then
      .message.content | split("\n")[0][:150]
    else
      ((.message.content[] | select(.type == "text") | .text | split("\n")[0][:150]) // "")
    end
  ' 2>/dev/null | grep -v '^$' | sed 's/^/- /' || true)

  outfile="$results_dir/${session_date}_$(echo "$filepath" | md5sum 2>/dev/null | cut -c1-8 || echo $$)"
  {
    echo "## $project ($session_date)"
    echo "- 作業ディレクトリ: $cwd"
    [ -n "$branch" ] && [ "$branch" != "null" ] && echo "- ブランチ: $branch"
    echo ""
    echo "### 最初のユーザーメッセージ"
    [ -n "$user_msgs" ] && echo "$user_msgs"
    echo ""
  } > "$outfile"
done
WORKER_EOF
  chmod +x "$TMPDIR_WORK/list_worker.sh"

  # ファイルをバッチに分けて並列実行（xargs -P でプロセスあたり複数ファイル処理）
  find "$SESSIONS_DIR" -name "*.jsonl" -type f -not -path "*/subagents/*" 2>/dev/null | \
    xargs -P "$NPROC" -n 20 bash "$TMPDIR_WORK/list_worker.sh" \
      "$start_date" "$end_date" "$mtime_start" "$mtime_end" "$results_dir" "$IS_MACOS"

  # 結果を結合（ファイル名でソートされるので日付順）
  local output
  output=$(find "$results_dir" -type f 2>/dev/null | sort | xargs cat 2>/dev/null)

  if [ -n "$output" ]; then
    echo "$output" | head -n 500
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

  # grep -l のチェーンで AND フィルタ（xargs -P で並列grep）
  local matched_files
  matched_files=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f -not -path "*/subagents/*" 2>/dev/null)

  local kw
  for kw in "${keywords[@]}"; do
    matched_files=$(echo "$matched_files" | xargs -P "$NPROC" grep -li "$kw" 2>/dev/null || true)
    [ -z "$matched_files" ] && break
  done

  if [ -z "$matched_files" ]; then
    echo "(該当するセッションはありませんでした)"
    return
  fi

  local results_dir="$TMPDIR_WORK/search_results"
  mkdir -p "$results_dir"

  # ワーカースクリプト
  cat > "$TMPDIR_WORK/search_worker.sh" << 'WORKER_EOF'
#!/bin/bash
results_dir="$1" is_macos="$2"
shift 2

# キーワードと残りのファイルパスを分離（-- で区切る）
keywords=()
filepaths=()
found_sep=false
for arg in "$@"; do
  if [[ "$arg" == "--" ]]; then
    found_sep=true
    continue
  fi
  if $found_sep; then
    filepaths+=("$arg")
  else
    keywords+=("$arg")
  fi
done

for filepath in "${filepaths[@]}"; do
  project=$(echo "$filepath" | sed "s|.*projects/||" | cut -d'/' -f1)

  first_user_line=$(grep -m1 '"type":"user"' "$filepath" 2>/dev/null) || true
  session_date="unknown"
  cwd="unknown"
  branch=""

  if [ -n "$first_user_line" ]; then
    session_info=$(echo "$first_user_line" | jq -r '[.timestamp // "", .cwd // "unknown", .gitBranch // ""] | @tsv' 2>/dev/null) || true
    IFS=$'\t' read -r timestamp cwd branch <<< "$session_info"
    if [ -n "$timestamp" ]; then
      if [[ "$is_macos" == "true" ]]; then
        utc_datetime="${timestamp%.*}+0000"
        session_date=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$utc_datetime" "+%Y-%m-%d" 2>/dev/null) || session_date="unknown"
      else
        session_date=$(date -d "$timestamp" "+%Y-%m-%d" 2>/dev/null) || session_date="unknown"
      fi
    fi
  fi

  match_lines=""
  for kw in "${keywords[@]}"; do
    kw_matches=$(grep -i "$kw" "$filepath" 2>/dev/null | head -5 | jq -r '
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
    ' 2>/dev/null | grep -v '^$' | sed 's/^/- /' || true)
    [ -n "$kw_matches" ] && match_lines="${match_lines}${kw_matches}"$'\n'
  done

  outfile="$results_dir/${session_date}_$(echo "$filepath" | md5sum 2>/dev/null | cut -c1-8 || echo $$)"
  {
    echo "## $project ($session_date)"
    echo "- 作業ディレクトリ: ${cwd:-unknown}"
    [ -n "$branch" ] && [ "$branch" != "null" ] && echo "- ブランチ: $branch"
    echo ""
    echo "### マッチした内容"
    [ -n "$match_lines" ] && echo "$match_lines"
    echo ""
  } > "$outfile"
done
WORKER_EOF
  chmod +x "$TMPDIR_WORK/search_worker.sh"

  # キーワードを先に、-- の後にファイルパスを渡す
  echo "$matched_files" | \
    xargs -P "$NPROC" -n 10 bash "$TMPDIR_WORK/search_worker.sh" \
      "$results_dir" "$IS_MACOS" "${keywords[@]}" --

  # 結果を結合（新しい順）
  local output
  output=$(find "$results_dir" -type f 2>/dev/null | sort -r | xargs cat 2>/dev/null)

  if [ -n "$output" ]; then
    echo "$output" | head -n 500
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

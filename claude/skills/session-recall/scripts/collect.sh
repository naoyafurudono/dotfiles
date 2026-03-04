#!/bin/bash
# セッションログを分析するスクリプト
# 使い方:
#   collect.sh list [日付指定]    - セッション一覧
#   collect.sh search [キーワード...] - キーワード検索
#
# 日付指定: today(デフォルト), yesterday, YYYY-MM-DD, YYYY-MM-DD..YYYY-MM-DD, 7d
# subagents は除外（メインセッションのみ）
#
# 高速化: 並列grep→単一jqパイプラインでプロセス起動を最小化

SESSIONS_DIR="$HOME/.claude/projects"
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

NPROC=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 8)

IS_MACOS=false
[[ "$(uname)" == "Darwin" ]] && IS_MACOS=true

# --- 日付ユーティリティ ---

date_today() { date +%Y-%m-%d; }

date_yesterday() {
  if $IS_MACOS; then date -v-1d +%Y-%m-%d; else date -d "yesterday" +%Y-%m-%d; fi
}

date_add_days() {
  local base_date="$1" days="$2"
  if $IS_MACOS; then
    date -j -v"${days}d" -f "%Y-%m-%d" "$base_date" +%Y-%m-%d 2>/dev/null || echo "$base_date"
  else
    date -d "$base_date ${days} days" +%Y-%m-%d 2>/dev/null || echo "$base_date"
  fi
}

# 全 jsonl ファイルのパスを列挙（subagents 除外）
find_session_files() {
  find "$SESSIONS_DIR" -name "*.jsonl" -type f -not -path "*/subagents/*" 2>/dev/null
}

# バッチ grep ワーカー: 各ファイルの先頭N件のユーザー行を "filepath\tJSON" 形式で出力
# $1=取得行数, $2..=ファイルパス
write_grep_worker() {
  cat > "$TMPDIR_WORK/grep_worker.sh" << 'WEOF'
n="$1"; shift
for f in "$@"; do
  grep '"type":"user"' "$f" 2>/dev/null | head -"$n" | while IFS= read -r line; do
    printf '%s\t%s\n' "$f" "$line"
  done
done
WEOF
}

# --- list モード ---

list_sessions() {
  local date_spec="${1:-today}"
  local start_date end_date

  case "$date_spec" in
    today)     start_date=$(date_today); end_date="$start_date" ;;
    yesterday) start_date=$(date_yesterday); end_date="$start_date" ;;
    *..*)      start_date="${date_spec%..*}"; end_date="${date_spec#*..}" ;;
    *d)        end_date=$(date_today); start_date=$(date_add_days "$end_date" "-${date_spec%d}") ;;
    *)         start_date="$date_spec"; end_date="$date_spec" ;;
  esac

  echo "# セッション一覧: $start_date ~ $end_date"
  echo ""

  write_grep_worker

  # 並列 grep (先頭3行) → 単一 jq で日付フィルタ+メッセージ抽出+Markdown整形を一括処理
  local output
  output=$(find_session_files | \
    xargs -P "$NPROC" -n 20 bash "$TMPDIR_WORK/grep_worker.sh" 3 | \
    jq -r -R -s --arg start "$start_date" --arg end "$end_date" '
      # 入力を行に分割してパース
      [split("\n") | .[] | select(length > 0) |
        split("\t") | select(length >= 2) |
        {fp: .[0], obj: ((.[1:] | join("\t")) | try fromjson catch null)} |
        select(.obj != null)
      ] |

      # ファイルパスでグループ化
      group_by(.fp) | map(
        .[0].fp as $fp |
        .[0].obj as $first |
        ($first.timestamp // "") as $ts |
        (if ($ts | length) > 0 then ($ts | split("T")[0]) else null end) as $session_date |

        # 日付範囲フィルタ
        select($session_date != null and $session_date >= $start and $session_date <= $end) |

        {
          session_date: $session_date,
          project: ($fp | split("projects/")[1] | split("/")[0]),
          cwd: ($first.cwd // "unknown"),
          branch: ($first.gitBranch // ""),
          msgs: [.[] | .obj |
            if .message.content | type == "string" then
              .message.content | split("\n")[0][:150]
            else
              ((.message.content[]? | select(.type == "text") | .text | split("\n")[0][:150]) // "")
            end
          ] | map(select(length > 0))
        }
      ) |

      # 日付順ソート
      sort_by(.session_date) |

      # Markdown 出力
      map(
        "## " + .project + " (" + .session_date + ")\n" +
        "- 作業ディレクトリ: " + .cwd + "\n" +
        (if .branch != "" and .branch != "null" then "- ブランチ: " + .branch + "\n" else "" end) +
        "\n### 最初のユーザーメッセージ\n" +
        (.msgs | map("- " + .) | join("\n")) +
        "\n"
      ) | join("\n")
    ' 2>/dev/null)

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

  # AND フィルタ: grep -li チェーン（xargs -P で並列）
  local matched_files
  matched_files=$(find_session_files)

  local kw
  for kw in "${keywords[@]}"; do
    matched_files=$(echo "$matched_files" | xargs -P "$NPROC" grep -li "$kw" 2>/dev/null || true)
    [ -z "$matched_files" ] && break
  done

  if [ -z "$matched_files" ]; then
    echo "(該当するセッションはありませんでした)"
    return
  fi

  # マッチしたファイルのメタデータを一括取得（先頭1行のみ）
  write_grep_worker
  local meta_tsv
  meta_tsv=$(echo "$matched_files" | \
    xargs -P "$NPROC" -n 20 bash "$TMPDIR_WORK/grep_worker.sh" 1 | \
    jq -r -R -s '
      [split("\n") | .[] | select(length > 0) |
        split("\t") | select(length >= 2) |
        .[0] as $fp | ((.[1:] | join("\t")) | try fromjson catch null) as $obj |
        {
          fp: $fp,
          session_date: (if $obj != null and (($obj.timestamp // "") | length) > 0
                         then ($obj.timestamp | split("T")[0]) else "unknown" end),
          project: ($fp | split("projects/")[1] | split("/")[0]),
          cwd: (if $obj != null then ($obj.cwd // "unknown") else "unknown" end),
          branch: (if $obj != null then ($obj.gitBranch // "") else "" end)
        }
      ] | sort_by(.session_date) | reverse | .[] |
      [.fp, .session_date, .project, .cwd, .branch] | @tsv
    ' 2>/dev/null)

  if [ -z "$meta_tsv" ]; then
    echo "(該当するセッションはありませんでした)"
    return
  fi

  # マッチ行の抽出を並列バッチ実行
  local match_dir="$TMPDIR_WORK/matches"
  mkdir -p "$match_dir"

  printf '%s\n' "${keywords[@]}" > "$TMPDIR_WORK/keywords.txt"

  cat > "$TMPDIR_WORK/match_worker.sh" << 'WEOF'
kw_file="$1" match_dir="$2"
jq_filter='if .message then
  if .message.content | type == "string" then .message.content | split("\n")[0][:150]
  else ((.message.content[]? | select(.type == "text") | .text | split("\n")[0][:150]) // "") end
elif .content then
  if .content | type == "string" then .content | split("\n")[0][:150]
  else ((.content[]? | select(.type == "text") | .text | split("\n")[0][:150]) // "") end
else empty end'
shift 2
for filepath in "$@"; do
  result=""
  while IFS= read -r kw; do
    matches=$(grep -i "$kw" "$filepath" 2>/dev/null | head -5 | jq -r "$jq_filter" 2>/dev/null | grep -v '^$' | sed 's/^/- /')
    [ -n "$matches" ] && result="${result}${matches}"$'\n'
  done < "$kw_file"
  hash=$(echo "$filepath" | md5sum 2>/dev/null | cut -c1-8 || echo $$)
  printf '%s' "$result" > "$match_dir/$hash"
done
WEOF

  echo "$matched_files" | \
    xargs -P "$NPROC" -n 10 bash "$TMPDIR_WORK/match_worker.sh" \
      "$TMPDIR_WORK/keywords.txt" "$match_dir"

  # 結果出力
  while IFS=$'\t' read -r filepath session_date project cwd branch; do
    echo "## $project ($session_date)"
    echo "- 作業ディレクトリ: ${cwd:-unknown}"
    [ -n "$branch" ] && [ "$branch" != "null" ] && echo "- ブランチ: $branch"
    echo ""
    echo "### マッチした内容"
    local hash
    hash=$(echo "$filepath" | md5sum 2>/dev/null | cut -c1-8 || echo $$)
    [ -f "$match_dir/$hash" ] && cat "$match_dir/$hash"
    echo ""
  done <<< "$meta_tsv" | head -n 500
}

# --- メインエントリポイント ---

mode="${1:-list}"
shift 2>/dev/null || true

case "$mode" in
  list)   list_sessions "$@" ;;
  search) search_sessions "$@" ;;
  *)      search_sessions "$mode" "$@" ;;
esac

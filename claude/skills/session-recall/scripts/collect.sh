#!/bin/bash
# セッションログを分析するスクリプト
# 使い方:
#   collect.sh list [日付指定]    - セッション一覧
#   collect.sh search [キーワード...] - キーワード検索
#
# 日付指定: today(デフォルト), yesterday, YYYY-MM-DD, YYYY-MM-DD..YYYY-MM-DD, 7d
# subagents は除外（メインセッションのみ）
#
# 高速化: rg の内部スレッド並列化 → 単一 jq パイプラインでプロセス起動を最小化

SESSIONS_DIR="$HOME/.claude/projects"
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

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

# rg でユーザー行を取得し、"filepath\tJSON" 形式に変換して出力
# $1=ファイルあたりの最大マッチ数, 残り=rg に渡す追加引数
rg_user_lines() {
  local max_count="$1"; shift
  rg -m"$max_count" --no-ignore --with-filename --no-line-number \
    '"type":"user"' "$SESSIONS_DIR" --glob '*.jsonl' "$@" 2>/dev/null | \
    grep -v '/subagents/' | \
    sed 's/\.jsonl:/\.jsonl\t/'
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

  # rg (先頭3行) → 単一 jq で日付フィルタ+メッセージ抽出+Markdown 整形を一括処理
  local output
  output=$(rg_user_lines 3 | \
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

  # AND フィルタ: rg -l チェーン
  local matched_files
  matched_files=$(rg -l --no-ignore -i "${keywords[0]}" "$SESSIONS_DIR" --glob '*.jsonl' 2>/dev/null | grep -v '/subagents/' || true)

  local kw
  for kw in "${keywords[@]:1}"; do
    [ -z "$matched_files" ] && break
    matched_files=$(echo "$matched_files" | xargs rg -l --no-ignore -i "$kw" 2>/dev/null || true)
  done

  if [ -z "$matched_files" ]; then
    echo "(該当するセッションはありませんでした)"
    return
  fi

  # メタデータ取得: マッチしたファイルの先頭ユーザー行を rg で一括取得
  local meta_tsv
  meta_tsv=$(echo "$matched_files" | xargs rg -m1 --no-ignore --with-filename --no-line-number '"type":"user"' 2>/dev/null | \
    sed 's/\.jsonl:/\.jsonl\t/' | \
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

  # マッチ行の内容抽出: rg で一括取得 → 単一 jq でパース
  # 全キーワード分のマッチ行を "filepath\tJSON" 形式で収集
  local all_matches=""
  for kw in "${keywords[@]}"; do
    local kw_matches
    kw_matches=$(echo "$matched_files" | xargs rg -m5 --no-ignore -i --with-filename --no-line-number "$kw" 2>/dev/null | \
      sed 's/\.jsonl:/\.jsonl\t/' || true)
    [ -n "$kw_matches" ] && all_matches="${all_matches}${kw_matches}"$'\n'
  done

  # マッチ行を jq でパースしてファイルパスごとにグループ化
  local match_data
  match_data=$(echo "$all_matches" | \
    jq -r -R -s '
      [split("\n") | .[] | select(length > 0) |
        split("\t") | select(length >= 2) |
        .[0] as $fp | ((.[1:] | join("\t")) | try fromjson catch null) as $obj |
        select($obj != null) |
        {
          fp: $fp,
          text: (
            if $obj.message then
              if ($obj.message.content | type) == "string" then
                $obj.message.content | split("\n")[0][:150]
              else
                ([$obj.message.content[]? | select(.type == "text") | .text | split("\n")[0][:150]] | first // "")
              end
            elif $obj.content then
              if ($obj.content | type) == "string" then
                $obj.content | split("\n")[0][:150]
              else
                ([$obj.content[]? | select(.type == "text") | .text | split("\n")[0][:150]] | first // "")
              end
            else ""
            end
          )
        } | select(.text | length > 0)
      ] |
      group_by(.fp) | map({
        fp: .[0].fp,
        lines: ([.[] | .text] | unique | map("- " + .) | join("\n"))
      }) | .[] | (.fp + "\t" + .lines)
    ' 2>/dev/null)

  # 結果出力: メタデータとマッチ行を結合
  while IFS=$'\t' read -r filepath session_date project cwd branch; do
    echo "## $project ($session_date)"
    echo "- 作業ディレクトリ: ${cwd:-unknown}"
    [ -n "$branch" ] && [ "$branch" != "null" ] && echo "- ブランチ: $branch"
    echo ""
    echo "### マッチした内容"
    # match_data からこのファイルのマッチ行を取得
    echo "$match_data" | while IFS=$'\t' read -r mfp mlines; do
      [ "$mfp" = "$filepath" ] && echo "$mlines"
    done
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

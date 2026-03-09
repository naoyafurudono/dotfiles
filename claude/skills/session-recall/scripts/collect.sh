#!/bin/bash
# shellcheck disable=SC2312  # パイプライン中間コマンドの戻り値マスキングは意図的
# セッションログを分析するスクリプト
# 使い方:
#   collect.sh list [日付指定]    - セッション一覧
#   collect.sh search [キーワード...] - キーワード検索
#
# 日付指定: today(デフォルト), yesterday, YYYY-MM-DD, YYYY-MM-DD..YYYY-MM-DD, 7d
# subagents は除外（メインセッションのみ）
#
# 高速化: rg の内部スレッド並列化 → 単一 jq パイプラインでプロセス起動を最小化

SESSIONS_DIR="${HOME}/.claude/projects"
USAGE_LOG="${HOME}/.claude/usage/session-recall.tsv"
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "${TMPDIR_WORK}"' EXIT

# --query オプション: 元のユーザー質問をログに記録するためのオプション
USER_QUERY=""

IS_MACOS=false
_uname=$(uname)
[[ "${_uname}" == "Darwin" ]] && IS_MACOS=true

# --- usage ログ ---

_start_ms() {
  if "${IS_MACOS}"; then
    perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000'
  else
    date +%s%3N
  fi
}

log_usage() {
  local mode="$1" args="$2" hit_count="$3" start_time="$4"
  local end_time elapsed ts
  end_time=$(_start_ms)
  elapsed=$(( end_time - start_time ))
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  mkdir -p "$(dirname "${USAGE_LOG}")"
  if [[ ! -f "${USAGE_LOG}" ]]; then
    printf "timestamp\tmode\targs\thit_count\telapsed_ms\tquery\n" > "${USAGE_LOG}"
  fi
  # query 内のタブと改行をエスケープしてTSVを壊さないようにする
  local safe_query
  safe_query=$(printf '%s' "${USER_QUERY}" | tr '\t\n' '  ')
  printf "%s\t%s\t%s\t%d\t%d\t%s\n" "${ts}" "${mode}" "${args}" "${hit_count}" "${elapsed}" "${safe_query}" >> "${USAGE_LOG}"
}

# --- 日付ユーティリティ ---

date_today() { date +%Y-%m-%d; }

date_yesterday() {
  if "${IS_MACOS}"; then date -v-1d +%Y-%m-%d; else date -d "yesterday" +%Y-%m-%d; fi
}

date_add_days() {
  local base_date="$1" days="$2"
  if "${IS_MACOS}"; then
    date -j -v"${days}d" -f "%Y-%m-%d" "${base_date}" +%Y-%m-%d 2>/dev/null || echo "${base_date}"
  else
    date -d "${base_date} ${days} days" +%Y-%m-%d 2>/dev/null || echo "${base_date}"
  fi
}

# rg でユーザー行を取得し、"filepath\tJSON" 形式に変換して出力
# $1=ファイルあたりの最大マッチ数, 残り=rg に渡す追加引数
rg_user_lines() {
  local max_count="$1"; shift
  rg -m"${max_count}" --no-ignore --with-filename --no-line-number \
    '"type":"user"' "${SESSIONS_DIR}" --glob '*.jsonl' "$@" 2>/dev/null | \
    grep -v '/subagents/' | \
    sed 's/\.jsonl:/\.jsonl\t/'
}

# --- list モード ---

list_sessions() {
  local date_spec="${1:-today}"
  local start_date end_date

  case "${date_spec}" in
    today)     start_date=$(date_today); end_date="${start_date}" ;;
    yesterday) start_date=$(date_yesterday); end_date="${start_date}" ;;
    *..*)      start_date="${date_spec%..*}"; end_date="${date_spec#*..}" ;;
    *d)        end_date=$(date_today); start_date=$(date_add_days "${end_date}" "-${date_spec%d}") ;;
    *)         start_date="${date_spec}"; end_date="${date_spec}" ;;
  esac

  echo "# セッション一覧: ${start_date} ~ ${end_date}"
  echo ""

  # rg (先頭3行) → 単一 jq で日付フィルタ+メッセージ抽出+コンパクト出力を一括処理
  local output
  output=$(rg_user_lines 3 | \
    jq -r -R -s --arg start "${start_date}" --arg end "${end_date}" '
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
          session_id: ($fp | split("/") | last | rtrimstr(".jsonl")),
          cwd: ($first.cwd // "unknown"),
          branch: ($first.gitBranch // ""),
          msgs: [.[] | .obj |
            if .message.content | type == "string" then
              .message.content | split("\n")[0][:150]
            else
              ((.message.content[]? | select(.type == "text") | .text | split("\n")[0][:150]) // "")
            end
          ] | map(select(length > 0)) |
            map(select(
              (startswith("/remote-control") | not) and
              (test("^Caveat:") | not) and
              (test("<local-command-caveat>") | not) and
              (test("<command-name>") | not) and
              (test("^\\[Request interrupted by user\\]$") | not)
            ))
        }
      ) |

      # 日付順ソート
      sort_by(.session_date) |

      # コンパクト出力（先頭行にセッション数）
      "\(length)\n" +
      (map(
        "- **" + .project + "** (" + .session_date + ") `" + .session_id + "`\n" +
        "  - dir: " + .cwd +
          (if .branch != "" and .branch != "null" then " | " + .branch else "" end) + "\n" +
        "  - 発言: " + (.msgs | join(" / "))
      ) | join("\n"))
    ' 2>/dev/null)

  # 先頭行はセッション数
  local count="${output%%$'\n'*}"
  echo "${count:-0}" > "${TMPDIR_WORK}/hit_count"
  if [[ -n "${output}" ]] && [[ "${count}" != "0" ]]; then
    echo "${output}" | tail -n +2 | head -n 500
  else
    echo "(該当するセッションはありませんでした)"
  fi
}

# --- search モード ---

# テキスト抽出用 jq ヘルパー（メッセージオブジェクトからテキストの先頭行を取得）
JQ_EXTRACT_TEXT='
def extract_text:
  if .message then
    if (.message.content | type) == "string" then
      .message.content | split("\n")[0][:150]
    else
      ([.message.content[]? | select(.type == "text") | .text | split("\n")[0][:150]] | first // "")
    end
  elif .content then
    if (.content | type) == "string" then
      .content | split("\n")[0][:150]
    else
      ([.content[]? | select(.type == "text") | .text | split("\n")[0][:150]] | first // "")
    end
  else ""
  end;
def is_noise:
  startswith("/remote-control") or
  test("^Caveat:") or
  test("<local-command-caveat>") or
  test("<command-name>") or
  test("^\\[Request interrupted by user\\]$");
'

search_sessions() {
  local keywords=("$@")

  if [[ ${#keywords[@]} -eq 0 ]]; then
    echo "エラー: 検索キーワードを指定してください"
    exit 1
  fi

  echo "# セッション検索: ${keywords[*]}"
  echo ""

  # AND フィルタ: rg -l チェーン（パスのみマッチは後段で除外される）
  local matched_files
  matched_files=$(rg -l --no-ignore -i "${keywords[0]}" "${SESSIONS_DIR}" --glob '*.jsonl' 2>/dev/null | grep -v '/subagents/' || true)

  local kw
  for kw in "${keywords[@]:1}"; do
    [[ -z "${matched_files}" ]] && break
    matched_files=$(echo "${matched_files}" | xargs rg -l --no-ignore -i "${kw}" 2>/dev/null || true)
  done

  if [[ -z "${matched_files}" ]]; then
    echo "(該当するセッションはありませんでした)"
    return
  fi

  # マッチ行の内容抽出: 全キーワードを OR パターンで1回の rg で取得 → 単一 jq でパース
  # キーワード数に関わらず xargs rg は1回のみ実行
  local or_pattern
  or_pattern=$(printf '%s\n' "${keywords[@]}" | paste -sd'|' -)
  local all_matches
  all_matches=$(echo "${matched_files}" | xargs rg -m1 --no-ignore -i --with-filename --no-line-number "${or_pattern}" 2>/dev/null | \
    grep -v '/subagents/' | sed 's/\.jsonl:/\.jsonl\t/' || true)

  # マッチ行をファイルパスごとにグループ化（ノイズ除外、テキストのみ） → JSON 配列
  local match_json
  match_json=$(echo "${all_matches}" | \
    jq -c -R -s "${JQ_EXTRACT_TEXT}"'
      [split("\n") | .[] | select(length > 0) |
        split("\t") | select(length >= 2) |
        .[0] as $fp | ((.[1:] | join("\t")) | try fromjson catch null) as $obj |
        select($obj != null) |
        { fp: $fp, text: ($obj | extract_text) } |
        select(.text | length > 0) |
        select(.text | is_noise | not)
      ] |
      group_by(.fp) | map({
        key: .[0].fp,
        value: ([.[] | .text] | unique)
      }) | from_entries
    ' 2>/dev/null)

  # メタデータ + 最初のユーザーメッセージ取得 → JSON 配列
  local meta_json
  meta_json=$(echo "${matched_files}" | xargs rg -m1 --no-ignore --with-filename --no-line-number '"type":"user"' 2>/dev/null | \
    grep -v '/subagents/' | sed 's/\.jsonl:/\.jsonl\t/' | \
    jq -c -R -s "${JQ_EXTRACT_TEXT}"'
      [split("\n") | .[] | select(length > 0) |
        split("\t") | select(length >= 2) |
        .[0] as $fp | ((.[1:] | join("\t")) | try fromjson catch null) as $obj |
        select($obj != null) |
        {
          fp: $fp,
          session_date: (if (($obj.timestamp // "") | length) > 0
                         then ($obj.timestamp | split("T")[0]) else "unknown" end),
          project: ($fp | split("projects/")[1] | split("/")[0]),
          session_id: ($fp | split("/") | last | rtrimstr(".jsonl")),
          cwd: ($obj.cwd // "unknown"),
          branch: ($obj.gitBranch // ""),
          first_msg: ($obj | extract_text)
        }
      ] | sort_by(.session_date) | reverse
    ' 2>/dev/null)

  if [[ -z "${meta_json}" ]] || [[ "${meta_json}" = "[]" ]]; then
    echo "0" > "${TMPDIR_WORK}/hit_count"
    echo "(該当するセッションはありませんでした)"
    return
  fi

  # 単一 jq でメタデータとマッチ行を結合 → Markdown 出力（先頭行にセッション数）
  local output
  output=$(jq -r -n --argjson meta "${meta_json}" --argjson matches "${match_json:-{\}}" '
    [$meta[] |
      (.fp) as $fp |
      ($matches[$fp] // []) as $match_texts |
      # マッチ行が空ならスキップ（ファイルパスのみのマッチ）
      select(($match_texts | length) > 0) |
      "- **" + .project + "** (" + .session_date + ") `" + .session_id + "`\n" +
      "  - dir: " + .cwd +
        (if .branch != "" and .branch != "null" then " | " + .branch else "" end) + "\n" +
      (if (.first_msg | length) > 0 then "  - 発言: " + .first_msg + "\n" else "" end) +
      "  - マッチ: " + ($match_texts | join(" / "))
    ] | "\(length)\n" + join("\n")
  ' 2>/dev/null)

  local count="${output%%$'\n'*}"
  echo "${count:-0}" > "${TMPDIR_WORK}/hit_count"
  if [[ -n "${output}" ]] && [[ "${count}" != "0" ]]; then
    echo "${output}" | tail -n +2 | head -n 500
  else
    echo "(該当するセッションはありませんでした)"
  fi
}

# --- メインエントリポイント ---

# --query オプションを先にパース（位置に関わらず抽出）
args=()
for arg in "$@"; do
  if [[ "${arg}" == --query=* ]]; then
    USER_QUERY="${arg#--query=}"
  else
    args+=("${arg}")
  fi
done
set -- "${args[@]}"

# mode が指定されず、--query= だけが渡された場合: query の中身をキーワードとして search する
if [[ $# -eq 0 ]] && [[ -n "${USER_QUERY}" ]]; then
  mode="search"
  # USER_QUERY をキーワードとして分割して渡す
  # shellcheck disable=SC2086  # 意図的な word splitting
  set -- ${USER_QUERY}
else
  mode="${1:-list}"
  shift 2>/dev/null || true
fi

_start=$(_start_ms)

case "${mode}" in
  list|一覧) list_sessions "$@" ;;
  search)    search_sessions "$@" ;;
  --query|--query=*)
    # --query がモードとして渡された場合: パース漏れした query 値をキーワードとして検索
    remaining="${mode#--query}"
    remaining="${remaining#=}"
    if [[ -n "${remaining}" ]]; then
      # shellcheck disable=SC2086  # 意図的な word splitting
      search_sessions ${remaining} "$@"
    elif [[ $# -gt 0 ]]; then
      search_sessions "$@"
    else
      list_sessions
    fi
    ;;
  *)         search_sessions "${mode}" "$@" ;;
esac

hit_count=$(cat "${TMPDIR_WORK}/hit_count" 2>/dev/null || echo 0)
log_usage "${mode}" "$*" "${hit_count}" "${_start}"

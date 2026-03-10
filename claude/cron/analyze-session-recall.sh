#!/bin/bash
set -euo pipefail

# session-recall の使用ログを分析して改善提案を生成する
# crontab から1日1回実行される想定
#
# 入力: ~/.claude/usage/session-recall.tsv
# 出力: ~/.claude/reports/session-recall.md

USAGE_LOG="${HOME}/.claude/usage/session-recall.tsv"
REPORT_FILE="${HOME}/.claude/reports/session-recall.md"
LAST_ANALYZED="${HOME}/.claude/cron/state/session-recall-last-line"

mkdir -p "$(dirname "${REPORT_FILE}")" "$(dirname "${LAST_ANALYZED}")"

if [[ ! -f "${USAGE_LOG}" ]]; then
  exit 0
fi

total_lines=$(wc -l < "${USAGE_LOG}" | tr -d ' ')
last_line=$(cat "${LAST_ANALYZED}" 2>/dev/null || echo "1")

# ヘッダ行を除く新規行数
new_lines=$((total_lines - last_line))
if [[ ${new_lines} -lt 5 ]]; then
  # 新規データが5件未満なら分析しない
  exit 0
fi

# --- 分析 ---

# ヘッダ行をスキップして全データ行を対象にする
data=$(tail -n +2 "${USAGE_LOG}")

total_queries=$(echo "${data}" | wc -l | tr -d ' ')
zero_hits=$(echo "${data}" | awk -F'\t' '$4 == 0' | wc -l | tr -d ' ')

if [[ ${total_queries} -gt 0 ]]; then
  zero_hit_pct=$((zero_hits * 100 / total_queries))
else
  zero_hit_pct=0
fi

# 平均実行時間
avg_ms=$(echo "${data}" | awk -F'\t' '{ sum += $5; n++ } END { if (n>0) printf "%d", sum/n; else print 0 }')

# 遅いクエリ (1000ms以上)
slow_queries=$(echo "${data}" | awk -F'\t' '$5 >= 1000 { printf "  - %s %s (%dms)\n", $2, $3, $5 }')

# ゼロヒットのクエリ一覧
zero_hit_queries=$(echo "${data}" | awk -F'\t' '$4 == 0 { printf "  - %s %s\n", $2, $3 }')

# モード別の使用回数
mode_counts=$(echo "${data}" | awk -F'\t' '{ modes[$2]++ } END { for (m in modes) printf "  - %s: %d\n", m, modes[m] }')

# --- レポート生成 ---

cat > "${REPORT_FILE}" << EOF
# session-recall 分析レポート

生成日時: $(date '+%Y-%m-%d %H:%M' || true)
対象データ: ${total_queries} 件

## サマリ

| 指標 | 値 |
|------|-----|
| 総クエリ数 | ${total_queries} |
| ゼロヒット数 | ${zero_hits} (${zero_hit_pct}%) |
| 平均実行時間 | ${avg_ms}ms |

## モード別使用回数

${mode_counts}

EOF

if [[ -n "${zero_hit_queries}" ]]; then
  cat >> "${REPORT_FILE}" << EOF
## ゼロヒットクエリ

以下のクエリは結果が0件でした。検索ロジックの改善を検討してください:

${zero_hit_queries}

EOF
fi

if [[ -n "${slow_queries}" ]]; then
  cat >> "${REPORT_FILE}" << EOF
## 遅いクエリ (1000ms以上)

${slow_queries}

EOF
fi

# 改善提案
suggestions=""

if [[ ${zero_hit_pct} -ge 30 ]]; then
  suggestions="${suggestions}
- ゼロヒット率が ${zero_hit_pct}% と高い。検索のフォールバック（部分一致、あいまい検索）の導入を検討"
fi

if [[ ${avg_ms} -ge 500 ]]; then
  suggestions="${suggestions}
- 平均実行時間が ${avg_ms}ms。インデックス作成やキャッシュの検討を"
fi

if [[ -n "${suggestions}" ]]; then
  cat >> "${REPORT_FILE}" << EOF
## 改善提案
${suggestions}
EOF
fi

# 分析済み行数を記録
echo "${total_lines}" > "${LAST_ANALYZED}"

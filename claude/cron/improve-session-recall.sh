#!/bin/bash
set -euo pipefail

# session-recall スキルの自動改善スクリプト
# crontab から定期実行される
#
# 1. 使用ログを分析してレポートを生成
# 2. 改善が必要なら claude CLI で改善を実行・コミット

# cron 実行時は問題ないが、手動テスト時にネスト防止を回避する
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ACCESS_TOKEN

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORT_FILE="${HOME}/.claude/reports/session-recall.md"
LOG_DIR="${HOME}/.claude/cron/logs"
DOTFILES_DIR="${HOME}/src/github.com/naoyafurudono/dotfiles"

mkdir -p "${LOG_DIR}"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_DIR}/improve-session-recall.log"
}

# --- Step 1: 分析レポート生成 ---
"${SCRIPT_DIR}/analyze-session-recall.sh"

if [[ ! -f "${REPORT_FILE}" ]]; then
  log "No report generated (insufficient data). Skipping."
  exit 0
fi

# --- Step 2: claude CLI で改善を実行 ---
REPORT=$(cat "${REPORT_FILE}")

log "Report generated. Launching claude for improvement."

PROMPT=$(cat <<'PROMPT_EOF'
あなたは session-recall スキルの自動改善エージェントです。

以下の分析レポートに基づいて、session-recall スキルを改善してください。

## 分析レポート

REPORT_PLACEHOLDER

## 対象ファイル

このリポジトリ (dotfiles) 内のパスで指定する。
~/.claude は ~/.config/claude へのシンボリックリンクであり、
このリポジトリの claude/ ディレクトリと同一である。

- claude/skills/session-recall/scripts/collect.sh (検索・一覧ロジック)
- claude/skills/session-recall/SKILL.md (プロンプト・引数設計)
- claude/skills/session-recall/REQUIREMENTS.md (要件定義)
- claude/cron/analyze-session-recall.sh (分析スクリプト)
- claude/cron/improve-session-recall.sh (この改善スクリプト自体)

## ルール

1. まず全対象ファイルを読んで現状を把握する
2. レポートの内容から最も効果の高い改善を1つ選んで実施する
3. 改善が不要と判断した場合は何もせず終了する
4. 変更後はテスト可能ならテストする（collect.sh なら実行して動作確認）
5. 変更があれば git commit する
6. コミットメッセージは改善内容を簡潔に記述する
PROMPT_EOF
)

# レポートをプロンプトに埋め込む
PROMPT="${PROMPT/REPORT_PLACEHOLDER/${REPORT}}"

cd "${DOTFILES_DIR}"

claude -p \
  --permission-mode bypassPermissions \
  --model sonnet \
  --max-budget-usd 1 \
  "${PROMPT}" \
  >> "${LOG_DIR}/improve-session-recall.log" 2>&1

log "Claude execution completed."

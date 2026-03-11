#!/bin/bash
# tmux/claude-session-save.sh と claude-session-restore.sh のテスト
#
# tmux の実体は不要。モックして入出力の正しさを検証する。
# jq は本物を使用する。

set -eu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TEST_TMPDIR}"' EXIT

failures=0

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

pass() {
  echo "PASS: $1"
}

# テスト用の PATH にモック tmux を配置
MOCK_BIN="${TEST_TMPDIR}/bin"
mkdir -p "${MOCK_BIN}"

SEND_KEYS_LOG="${TEST_TMPDIR}/send-keys.log"
export SEND_KEYS_LOG

cat > "${MOCK_BIN}/tmux" << 'MOCK'
#!/bin/bash
case "$1" in
  display-message)
    echo "main:0.1"
    ;;
  has-session)
    exit "${HAS_SESSION:-0}"
    ;;
  send-keys)
    echo "$@" >> "${SEND_KEYS_LOG}"
    ;;
esac
MOCK
chmod +x "${MOCK_BIN}/tmux"

export PATH="${MOCK_BIN}:${PATH}"

# ==============================
# save のテスト
# ==============================

# --- テスト1: セッション開始時にペインとセッションIDが記録される ---
test_save_records_mapping() {
  local test_home="${TEST_TMPDIR}/test1"
  mkdir -p "${test_home}"

  echo '{"session_id":"abc-123","hook_event_name":"SessionStart"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  local mapping="${test_home}/.tmux/resurrect/claude-sessions.txt"
  if [[ ! -f "${mapping}" ]]; then
    fail "テスト1: マッピングファイルが作成されない"
    return
  fi

  local content
  content="$(cat "${mapping}")"
  if [[ "${content}" == "main:0.1	abc-123" ]]; then
    pass "テスト1: セッション開始時にペインとセッションIDが記録される"
  else
    fail "テスト1: 期待='main:0.1<TAB>abc-123', 実際='${content}'"
  fi
}

# --- テスト2: 同じペインでセッションを再開すると、古いエントリが上書きされる ---
test_save_overwrites_same_pane() {
  local test_home="${TEST_TMPDIR}/test2"
  mkdir -p "${test_home}/.tmux/resurrect"

  echo '{"session_id":"old-session","hook_event_name":"SessionStart"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  echo '{"session_id":"new-session","hook_event_name":"SessionStart"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  local mapping="${test_home}/.tmux/resurrect/claude-sessions.txt"
  local count
  count="$(wc -l < "${mapping}" | tr -d ' ')"
  local content
  content="$(cat "${mapping}")"

  if [[ "${count}" == "1" && "${content}" == "main:0.1	new-session" ]]; then
    pass "テスト2: 同じペインの古いエントリが上書きされる"
  else
    fail "テスト2: 行数=${count}, 内容='${content}'"
  fi
}

# --- テスト3: tmux 外（TMUX_PANE未設定）では何もしない ---
test_save_noop_without_tmux() {
  local test_home="${TEST_TMPDIR}/test3"
  mkdir -p "${test_home}"

  echo '{"session_id":"abc-123","hook_event_name":"SessionStart"}' \
    | HOME="${test_home}" TMUX_PANE="" bash "${SCRIPT_DIR}/claude-session-save.sh"

  if [[ ! -d "${test_home}/.tmux" ]]; then
    pass "テスト3: tmux 外では何もしない"
  else
    fail "テスト3: tmux 外なのにファイルが作成された"
  fi
}

# --- テスト4: セッション終了時にエントリが削除される ---
test_save_removes_on_session_end() {
  local test_home="${TEST_TMPDIR}/test4"
  mkdir -p "${test_home}/.tmux/resurrect"

  # セッション開始
  echo '{"session_id":"abc-123","hook_event_name":"SessionStart"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  # セッション終了
  echo '{"session_id":"abc-123","hook_event_name":"SessionEnd"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  local mapping="${test_home}/.tmux/resurrect/claude-sessions.txt"
  local count
  count="$(wc -l < "${mapping}" | tr -d ' ')"

  if [[ "${count}" == "0" ]]; then
    pass "テスト4: セッション終了時にエントリが削除される"
  else
    local remaining
    remaining="$(cat "${mapping}")"
    fail "テスト4: エントリが残っている: ${remaining}"
  fi
}

# --- テスト5: 別ペインのエントリは終了時に影響されない ---
test_save_end_preserves_other_panes() {
  local test_home="${TEST_TMPDIR}/test5"
  mkdir -p "${test_home}/.tmux/resurrect"

  # ペイン main:0.1 に記録（モックは常に main:0.1 を返す）
  echo '{"session_id":"session-a","hook_event_name":"SessionStart"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  # 別ペインのエントリを手動で追加
  printf 'main:1.0\tsession-b\n' >> "${test_home}/.tmux/resurrect/claude-sessions.txt"

  # main:0.1 のセッション終了
  echo '{"session_id":"session-a","hook_event_name":"SessionEnd"}' \
    | HOME="${test_home}" TMUX_PANE="%5" bash "${SCRIPT_DIR}/claude-session-save.sh"

  local mapping="${test_home}/.tmux/resurrect/claude-sessions.txt"
  local content
  content="$(cat "${mapping}")"

  if [[ "${content}" == "main:1.0	session-b" ]]; then
    pass "テスト5: 別ペインのエントリは終了時に影響されない"
  else
    fail "テスト5: 内容='${content}'"
  fi
}

# ==============================
# restore のテスト
# ==============================

# --- テスト6: 記録されたペインで claude --resume が実行される ---
test_restore_sends_resume() {
  local test_home="${TEST_TMPDIR}/test6"
  mkdir -p "${test_home}/.tmux/resurrect"
  printf 'main:0.1\tabc-123\n' > "${test_home}/.tmux/resurrect/claude-sessions.txt"
  rm -f "${SEND_KEYS_LOG}"

  HAS_SESSION=0 HOME="${test_home}" bash "${SCRIPT_DIR}/claude-session-restore.sh"

  if [[ ! -f "${SEND_KEYS_LOG}" ]]; then
    fail "テスト6: send-keys が呼ばれなかった"
    return
  fi

  local logged
  logged="$(cat "${SEND_KEYS_LOG}")"
  if echo "${logged}" | grep -q "claude --resume abc-123"; then
    pass "テスト6: 記録されたペインで claude --resume が実行される"
  else
    fail "テスト6: 期待するコマンドが送信されなかった: ${logged}"
  fi
}

# --- テスト7: 存在しないペインはスキップされる ---
test_restore_skips_missing_pane() {
  local test_home="${TEST_TMPDIR}/test7"
  mkdir -p "${test_home}/.tmux/resurrect"
  printf 'main:0.1\tabc-123\n' > "${test_home}/.tmux/resurrect/claude-sessions.txt"
  rm -f "${SEND_KEYS_LOG}"

  HAS_SESSION=1 HOME="${test_home}" bash "${SCRIPT_DIR}/claude-session-restore.sh"

  if [[ ! -f "${SEND_KEYS_LOG}" ]]; then
    pass "テスト7: 存在しないペインはスキップされる"
  else
    fail "テスト7: 存在しないペインに send-keys が呼ばれた"
  fi
}

# --- テスト8: マッピングファイルがなければ何もしない ---
test_restore_noop_without_mapping() {
  local test_home="${TEST_TMPDIR}/test8"
  mkdir -p "${test_home}"
  rm -f "${SEND_KEYS_LOG}"

  HOME="${test_home}" bash "${SCRIPT_DIR}/claude-session-restore.sh"

  if [[ ! -f "${SEND_KEYS_LOG}" ]]; then
    pass "テスト8: マッピングファイルがなければ何もしない"
  else
    fail "テスト8: マッピングなしで send-keys が呼ばれた"
  fi
}

# テスト実行
test_save_records_mapping
test_save_overwrites_same_pane
test_save_noop_without_tmux
test_save_removes_on_session_end
test_save_end_preserves_other_panes
test_restore_sends_resume
test_restore_skips_missing_pane
test_restore_noop_without_mapping

echo ""
if [[ "${failures}" -eq 0 ]]; then
  echo "All tests passed."
  exit 0
else
  echo "${failures} test(s) failed."
  exit 1
fi

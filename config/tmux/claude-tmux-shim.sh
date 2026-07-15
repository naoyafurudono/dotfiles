#!/bin/sh
# Claude Code (agent teams) が PATH 経由で叩く tmux コマンドを書き換えるシム。
# ~/.local/bin/tmux -> このスクリプト の symlink で有効化する
# (~/.local/bin は PATH 上で /opt/homebrew/bin より先にあるため、
#  シェルから `tmux` を叩くプロセスはこのシムを経由する)。
#
# 目的: teammate ペイン生成時のレイアウト破壊を防ぐ。
#   1. split-window の -h を -v に書き換える（ペインは縦に生やす）
#   2. select-layout main-vertical を無視する（全ペイン強制再配置の抑止）
#   3. resize-pane -x 30% を無視する（リーダーペインの強制リサイズの抑止）
#
# split-window は Claude Code の呼び出しシグネチャ（-F '#{pane_id}' を含む）に
# 一致する場合のみ書き換え、それ以外の呼び出しは実 tmux へそのまま透過する。
# 注意: このシムを経由するシェルからは select-layout main-vertical /
# resize-pane -x 30% が常に no-op になる（tmux キーバインドや run-shell は
# tmux サーバー側で解決されるため影響しない）。
#
# 依存: Claude Code v2.1.x の内部実装 (TmuxBackend.createTeammatePaneWithLeader /
# rebalancePanesWithLeader)。Claude Code の更新で挙動が変わったらここを調整する。

REAL_TMUX=/opt/homebrew/bin/tmux

case "$1" in
split-window)
  # Claude Code の teammate 生成呼び出しか判定（-F '#{pane_id}' を含む）
  is_claude=0
  for a in "$@"; do
    [ "${a}" = "#{pane_id}" ] && is_claude=1
  done
  if [ "${is_claude}" -eq 1 ]; then
    # -h → -v、-l 70% → -l 50%（縦分割で新ペイン70%は大きすぎるため）。
    # "--" 以降は起動コマンドなので書き換えない。
    n=$#
    i=0
    expect_size=0
    past_cmd=0
    while [ "${i}" -lt "${n}" ]; do
      a=$1
      shift
      i=$((i + 1))
      if [ "${past_cmd}" -eq 0 ]; then
        if [ "${expect_size}" -eq 1 ]; then
          expect_size=0
          [ "${a}" = "70%" ] && a="50%"
        elif [ "${a}" = "-h" ]; then
          a="-v"
        elif [ "${a}" = "-l" ]; then
          expect_size=1
        elif [ "${a}" = "--" ]; then
          past_cmd=1
        fi
      fi
      set -- "$@" "${a}"
    done
  fi
  ;;
select-layout)
  for a in "$@"; do
    [ "${a}" = "main-vertical" ] && exit 0
  done
  ;;
resize-pane)
  prev=""
  for a in "$@"; do
    if [ "${prev}" = "-x" ] && [ "${a}" = "30%" ]; then
      exit 0
    fi
    prev=${a}
  done
  ;;
*) ;;
esac

exec "${REAL_TMUX}" "$@"

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository managing configuration files for various development tools using **chezmoi**.

## Repository Structure

- `home/` -- chezmoi ソースディレクトリ（`.chezmoiroot` で指定）
  - `home/dot_config/` -- `~/.config/` に配置される設定ファイル群
  - `home/.chezmoiignore` -- chezmoi 管理対象から除外するファイル（fish_variables 等の動的ファイル）
  - `home/symlink_dot_claude` -- `~/.claude` -> `~/.config/claude` のシンボリックリンク定義
  - `home/Library/LaunchAgents/` -- macOS の LaunchAgents plist
- トップレベルの旧設定ディレクトリ（`fish/`, `git/`, `nvim/` 等）は移行前の残存物で、将来削除予定

chezmoi の命名規則に従い、`dot_` プレフィックスはドットファイル、`executable_` プレフィックスは実行可能ファイル、`symlink_` プレフィックスはシンボリックリンク、`private_` プレフィックスはパーミッション制限付きファイルを示す。

## Configuration Management with chezmoi

### 設定の適用

```sh
chezmoi apply
```

### 新しい設定ファイルの追加

```sh
chezmoi add ~/.config/<path>
```

`home/dot_config/` 配下に chezmoi 形式でファイルが追加される。

### 設定の変更を反映

ローカルの `~/.config` 以下で設定を変更した後:

```sh
chezmoi re-add   # ローカルの変更を chezmoi ソースに反映
```

または `sconf` fish 関数を使うと、`chezmoi re-add` + git commit/push をまとめて実行できる。

### 動的ファイルの除外

chezmoi で管理すべきでないファイル（マシン固有の設定、ランタイムデータ等）は `home/.chezmoiignore` に追加する。

## Key Configuration Paths

設定ファイルは `home/dot_config/` 配下にある。主要なものは以下の通り:

- **nvim/**: Neovim config using lazy.nvim plugin manager
  - `init.lua` loads `config/options`, `config/lazy`, `config/keymaps`
  - Plugins defined in `lua/plugins/`
- **fish/**: Fish shell config
  - `config.fish` main config, loads `~/.local/fish/config.fish` for machine-specific settings
- **git/**: Git configuration with global hooks in `hooks/`
- **zed/**: Zed editor settings
- **ghostty/**: Terminal emulator config
- **claude/**: Claude Code settings and custom commands

## Git Workflow Notes

- git hooks are stored in `home/dot_config/git/hooks/` and configured via `core.hooksPath`
- Abbreviations for common git commands defined in fish config (a=add, c=commit, d=diff, s=status, p=pull)

## Working Preferences

- Review and update the task list after completing each task
- When the user's goal is achieved, improve the repository's CLAUDE.md based on the conversation if there are meaningful improvements

# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理している dotfiles リポジトリ。

## インストール

```sh
# chezmoi をインストール
sh -c "$(curl -fsLS get.chezmoi.io)"

# dotfiles を適用
chezmoi init --apply https://github.com/naoyafurudono/dotfiles.git
```

## 設定の変更

ローカルで設定を変更した後、chezmoi ソースに反映する:

```sh
chezmoi re-add
```

または fish shell の `sconf` 関数で re-add + git commit/push をまとめて実行できる。

## 新しい設定ファイルの追加

```sh
chezmoi add ~/.config/<path>
```

動的ファイル（マシン固有の設定等）は `home/.chezmoiignore` に追加して除外する。

## リポジトリ構造

- `home/` -- chezmoi ソースディレクトリ（`.chezmoiroot` で指定）
  - `home/dot_config/` -- `~/.config/` に配置される設定ファイル群
  - `home/.chezmoiignore` -- 管理対象から除外するファイル定義
  - `home/symlink_dot_claude` -- `~/.claude` シンボリックリンク定義
  - `home/Library/LaunchAgents/` -- macOS LaunchAgents

## memo

- [fish-kube-prompt](https://github.com/aluxian/fish-kube-prompt)
  - ほしければ手動でインストールする
  - プロンプトの設定はいい感じにしてあるので、手動で設定する必要はない

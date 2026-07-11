# CLAUDE.md

このリポジトリは chezmoi と mise で dotfiles と開発ツールを管理する。変更前に [docs/management-policy.md](docs/management-policy.md) を読み、その責務境界と変更ワークフローに従うこと。

## 必須ルール

- `.chezmoiroot` が指定する `home/` を唯一の source of truth とする。
- トップレベルに `fish/`、`nvim/`、`git/` などの複製を作らない。
- エージェントは実 HOME ではなく、原則として `home/` 以下を直接編集する。
- 実体から取り込む場合は `chezmoi re-add <target>` と対象を限定する。引数なしの `chezmoi re-add` は使わない。
- 秘密情報、認証情報、キャッシュ、マシン固有の絶対パスをコミットしない。`private_` は暗号化ではない。
- 言語ランタイムとポータブル CLI は mise、GUI・OSパッケージは Brewfile または apt 一覧に追加する。同じツールを複数の仕組みで管理しない。
- プロジェクト固有のバージョンをグローバル mise 設定へ追加しない。
- OS 差分には chezmoi の template data と `.chezmoiignore` を使い、ユーザー名やホームディレクトリをハードコードしない。
- bootstrap script の順序と `run_once_` / `run_onchange_` の意味を維持する。
- 変更後は `make check` を実行し、一つの意図ごとにコミットする。
- ユーザーの明示的な依頼なしに push しない。

## 主要パス

- `home/dot_config/`: `~/.config/` に配置する設定
- `home/dot_config/mise/config.toml`: グローバルな mise ツール
- `home/dot_config/dotfiles/`: OS パッケージの宣言
- `home/.chezmoi.toml.tmpl`: マシン固有データの初期化
- `home/.chezmoiignore`: OS 別・動的ファイルの除外
- `home/run_*`: bootstrap と依存導入
- `scripts/`: リポジトリ自体の lint/test

主要コマンド:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose --exclude=scripts
make check
```

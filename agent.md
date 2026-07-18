# CLAUDE.md

このリポジトリは mise で dotfiles と開発ツールを管理する。変更前に [docs/management-policy.md](docs/management-policy.md) を読み、その責務境界と変更ワークフローに従うこと。

## 必須ルール

- `config/` を唯一の source of truth とする。`~/.config/` は 1 ファイルずつの symlink であり、どちらを編集しても同じ実体が変わる。
- トップレベルに `fish/`、`nvim/`、`git/` などの複製を作らない。
- 新規ファイルの追加・削除・テンプレート変更後は `mise dotfiles apply` を実行する。既存ファイルの編集だけなら再適用は不要。
- 初回適用では `MISE_GLOBAL_CONFIG_FILE="$PWD/config/mise/config.toml" mise dotfiles apply --dry-run` を先に実行する。`mise dotfiles` が使えない場合は `mise self-update --yes` で mise を更新する。
- dry-run で既存ファイルとの衝突が出た場合、対象をバックアップしてから `--force` を使う。バックアップなしで既存の `~/.config` を上書きしない。
- 秘密情報、認証情報、キャッシュ、マシン固有の絶対パスをコミットしない。動的ファイル（`fish_variables`、`gh/hosts.yml` など）は `config/` に置かない。
- 言語ランタイムとポータブル CLI は mise、GUI・OSパッケージは Brewfile または apt 一覧に追加する。同じツールを複数の仕組みで管理しない。
- プロジェクト固有のバージョンをグローバル mise 設定へ追加しない。
- マシン差分は `templates/` の Tera テンプレート（`{{ env.HOME }}` など）で表現し、ユーザー名やホームディレクトリをハードコードしない。
- 変更後は `make check` を実行し、一つの意図ごとにコミットする。
- ユーザーの明示的な依頼なしに push しない。

## 主要パス

- `config/`: `~/.config/` に symlink される設定の実体
- `config/mise/config.toml`: グローバルな mise ツールと `[dotfiles]` マッピング
- `config/dotfiles/`: OS パッケージの宣言
- `templates/`: マシン依存値を含む設定の Tera テンプレート
- `scripts/`: リポジトリ自体の lint/test と OS パッケージ導入
- `mise.toml`: リポジトリ内タスク（`packages`, `check`）

主要コマンド:

```sh
# 初回適用
MISE_GLOBAL_CONFIG_FILE="$PWD/config/mise/config.toml" mise dotfiles apply --dry-run
MISE_GLOBAL_CONFIG_FILE="$PWD/config/mise/config.toml" mise dotfiles apply --yes

# 日常的な状態確認と再適用
mise dotfiles status
mise dotfiles apply --dry-run
mise dotfiles apply

# リポジトリの検証
make check
```

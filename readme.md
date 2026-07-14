# dotfiles

mise で設定ファイル・言語ランタイム・ポータブル CLI・OS パッケージを管理する dotfiles リポジトリです。

## 構成

- `config/`: `~/.config/` に 1 ファイルずつ symlink される設定の実体（mise dotfiles の `symlink-each`）
- `templates/`: マシン依存の値を含む設定の Tera テンプレート（ghostty、LaunchAgent plist）
- `config/mise/config.toml`: グローバルな mise 設定。`[tools]` と `[dotfiles]` マッピングを含む
- `config/dotfiles/`: OS パッケージの宣言（`Brewfile` / `packages-debian.txt`）
- `windows/`: Windows 用ファイル（現在は自動配置していない）
- `scripts/`, `Makefile`, `mise.toml`: リポジトリ自体の検証・運用タスク

## セットアップ（新しいマシン）

```sh
curl https://mise.run | sh
git clone https://github.com/naoyafurudono/dotfiles.git ~/src/github.com/naoyafurudono/dotfiles
cd ~/src/github.com/naoyafurudono/dotfiles

# 初回のみグローバル設定を明示して dotfiles を配置する
MISE_GLOBAL_CONFIG_FILE="$PWD/config/mise/config.toml" mise dotfiles apply --yes

ln -s .config/claude ~/.claude   # Claude Code 用の symlink
mise run packages                # OS パッケージ (macOS: brew bundle / Debian: apt)
mise install --yes               # 言語ランタイム・CLI
```

2 回目以降は `~/.config/mise/config.toml` が symlink されているため、環境変数の指定は不要です。

## 日常操作

設定ファイルは symlink なので、`~/.config/` 側を直接編集してもリポジトリの実体が変わります。`chezmoi re-add` のような取り込み操作は不要です。

```sh
# 変更の確認とコミット
git -C ~/src/github.com/naoyafurudono/dotfiles status
git -C ~/src/github.com/naoyafurudono/dotfiles diff

# 状態確認・再適用（新規ファイル追加後など）
mise dotfiles status
mise dotfiles apply --dry-run
mise dotfiles apply

# リポジトリ全体の検証
make check
```

## 新しいファイルの追加

リポジトリの `config/` 以下にファイルを置き、`mise dotfiles apply` で symlink を作成します。

追加後は `git diff` と `make check` で、秘密情報・ランタイムデータ・マシン固有の絶対パスが含まれていないことを確認してください。

詳細な責務分担、ファイル配置、更新手順は [管理方針](docs/management-policy.md) を参照してください。

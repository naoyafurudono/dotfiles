# dotfiles 管理方針

## 目的

このリポジトリは、複数マシンで再現可能な開発環境を、小さくレビュー可能な変更として維持する。設定、ツール、OS パッケージの所有者を一つに定め、同じ対象を複数の仕組みで管理しない。

## 責務の境界

| 対象                                     | 管理手段              | 主な場所                                  |
| ---------------------------------------- | --------------------- | ----------------------------------------- |
| dotfiles の配置（symlink・テンプレート） | mise dotfiles         | `config/mise/config.toml` の `[dotfiles]` |
| 設定の実体                               | Git                   | `config/`                                 |
| マシン・OS ごとの差分                    | Tera テンプレート     | `templates/`                              |
| mise 自体                                | mise.run インストーラ | readme のセットアップ手順                 |
| 言語ランタイム、ポータブル CLI           | mise `[tools]`        | `config/mise/config.toml`                 |
| macOS のシステムパッケージ、GUI アプリ   | Homebrew              | `config/dotfiles/Brewfile`                |
| Debian 系 Linux のシステムパッケージ     | apt                   | `config/dotfiles/packages-debian.txt`     |
| プロジェクト固有のツールバージョン       | 各プロジェクトの mise | 各リポジトリの `mise.toml`                |

mise 自体を Homebrew 側でも管理しない。言語ランタイムを Homebrew や手書き PATH でも管理しない。プロジェクト固有のバージョンをこのリポジトリのグローバル mise 設定へ追加しない。

## source of truth

管理対象の唯一の正は `config/` である。`~/.config/` 側は 1 ファイルずつの symlink（`symlink-each`）なので、実体側の編集はそのままリポジトリの変更になる。トップレベルに `fish/`、`nvim/`、`git/` などのミラーを作らない。

chezmoi のようなファイル名プレフィックスは使わない。ファイル名・実行権限・所有者権限は Git が保持するそのままの状態が配置される。

アプリが生成する動的ファイル（`fish_variables`、`gh/hosts.yml` など）は `config/` に置かず、`~/.config/` 側の実ファイルとして管理外で共存させる。誤って取り込んだ場合の安全網として `.gitignore` にも登録している。

秘密情報はコミットしない。必要ならパスワードマネージャー連携を別途導入する。

## マシン差分

マシン依存の値（ホームディレクトリなど）を含む設定は `templates/` に Tera テンプレートとして置き、`[dotfiles]` で `mode = "template"` を指定してレンダリング結果を実ファイルとして配置する。テンプレートからは `{{ env.HOME }}` のように環境変数を参照でき、ユーザー名やホームパスをハードコードしない。

マシンごとに値を変えたい場合は、管理外の `~/.config/mise/config.local.toml` の `[vars]` に定義し、テンプレートから `{{ vars.<name> | default(value=...) }}` で参照する（旧 chezmoi の `[data]` に相当。例: `ghostty_start_dir`）。テンプレートを変更したら `mise dotfiles apply` で再レンダリングする。

特定 OS にだけ必要なファイルも `config/` に含める。symlink が作られるだけで害がないものはそのまま許容し、配置自体が問題になるもの（Windows の `AppData` など）はマッピングせず `windows/` などに保管する。

## bootstrap と適用順序

新しいマシンでは readme の手順に従う。

1. mise.run で mise を導入する
2. リポジトリを clone し、`MISE_GLOBAL_CONFIG_FILE` を指定して `mise dotfiles apply` を実行する（以降はグローバル設定が symlink されるため指定不要）
3. `mise run packages` で OS パッケージを導入する
4. `mise install` で言語ランタイム・CLI を導入する

chezmoi の `run_once_` / `run_onchange_` に相当する自動実行はない。宣言ファイル（Brewfile、mise `[tools]`）を変更したら、対応するコマンドを明示的に実行する。

## 変更ワークフロー

symlink のため、`config/` を編集しても `~/.config/` を編集しても同じ実体が変わる。

1. ファイルを編集する（既存ファイルなら再適用は不要）
2. 新規ファイルの追加・削除・テンプレート変更時は `mise dotfiles apply` を実行する
3. `make check` を実行する
4. `git diff` を確認し、一つの責務ごとにコミットする

コミットには、依存一覧、個別アプリ設定、ドキュメントなど、レビュー可能な一つの意図だけを含める。生成キャッシュや無関係なローカル変更を混ぜない。自動的な `git add -A`、自動 commit/push は行わない。

## mise の更新

グローバルに常用するツールだけを `config/mise/config.toml` に置く。言語は互換性を意識した明示バージョンを基本とし、ポータブル CLI は mise registry の標準バックエンドを利用する。

```sh
# 設定を編集した後
mise install
mise doctor
```

mise 自体の更新は `mise self-update` で行う。

## OS パッケージの更新

macOS は Brewfile、Debian 系 Linux は一行一パッケージの一覧を変更し、`mise run packages` を実行する。アンインストールは自動化されないため、一覧から削除したパッケージが不要なら、影響を確認して明示的に削除する。

Linux は現在 apt のみ対応する。他のディストリビューションを加える場合は、既存分岐を暗黙に流用せず、マニフェストとテスト方針を追加する。

## 検証

`make check` は以下を行う。

- sh/bash と fish の構文確認
- shellcheck が利用可能なら静的解析
- 主要ファイルの存在・実行権限・動的ファイル混入の検証
- `[dotfiles]` 設定の parse と `mise dotfiles apply --dry-run` の成功確認
- whitespace error の確認

変更後の手動確認には次も利用する。

```sh
mise dotfiles status
mise dotfiles apply --dry-run
mise doctor
```

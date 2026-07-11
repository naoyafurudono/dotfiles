# dotfiles 管理方針

## 目的

このリポジトリは、複数マシンで再現可能な開発環境を、小さくレビュー可能な変更として維持する。設定、ツール、OS パッケージの所有者を一つに定め、同じ対象を複数の仕組みで管理しない。

## 責務の境界

| 対象 | 管理手段 | 主な場所 |
| --- | --- | --- |
| dotfiles、テンプレート、権限、シンボリックリンク | chezmoi | `home/` |
| マシン・OS ごとの差分 | chezmoi template / `.chezmoiignore` | `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore` |
| mise 自体 | chezmoi の bootstrap script | `home/run_once_before_00-install-mise.sh.tmpl` |
| 言語ランタイム、ポータブル CLI | mise | `home/dot_config/mise/config.toml` |
| macOS のシステムパッケージ、GUI アプリ | Homebrew | `home/dot_config/dotfiles/Brewfile` |
| Debian 系 Linux のシステムパッケージ | apt | `home/dot_config/dotfiles/packages-debian.txt` |
| プロジェクト固有のツールバージョン | 各プロジェクトの mise | 各リポジトリの `mise.toml` |

chezmoi と mise 自体を Homebrew 側でも管理しない。言語ランタイムを Homebrew や手書き PATH でも管理しない。プロジェクト固有のバージョンをこのリポジトリのグローバル mise 設定へ追加しない。

## source of truth

`.chezmoiroot` が `home/` を指定しているため、管理対象の唯一の正は `home/` である。トップレベルに `fish/`、`nvim/`、`git/` などのミラーを作らない。

chezmoi の主要な命名規則は次のとおり。

- `dot_`: 先頭のドット
- `executable_`: 実行権限
- `private_`: 所有者だけに制限した権限。暗号化を意味しない
- `symlink_`: 内容をリンク先とするシンボリックリンク
- `.tmpl`: Go template としてレンダリング

秘密情報はコミットしない。必要なら chezmoi の暗号化またはパスワードマネージャー連携を別途導入する。単に `private_` を付けても秘密情報は Git 履歴から隠れない。

## マシン差分

初期値は `home/.chezmoi.toml.tmpl` の `[data]` に定義する。現在は `machineType` と `ghosttyStartDir` を利用する。OS や CPU は、ハードコードしたユーザー名やホームパスではなく `.chezmoi.os`、`.chezmoi.arch`、`.chezmoi.homeDir` から判定する。

特定 OS にだけ必要なファイルは、テンプレート化された `home/.chezmoiignore` で除外する。動的ファイル、認証情報、キャッシュも同じ場所で除外する。除外を追加するときは、設定本体を誤って除外していないか `chezmoi ignored` で確認する。

## bootstrap と適用順序

スクリプト名の番号は実行順序を表す。

1. `run_once_before_00`: mise 自体を一度だけ導入
2. chezmoi が管理ファイルをレンダリング・配置
3. `run_onchange_after_10`: OS パッケージ一覧が変わったときに Homebrew または apt を実行
4. `run_onchange_after_20`: mise 設定が変わったときに `mise install`

`run_once_` は再実行されないため、本当に一度だけでよい初期化に限定する。宣言ファイルの変更へ追従すべき処理は、内容のハッシュをコメントに含めた `run_onchange_` にする。スクリプトは対話シェルの設定やエイリアスに依存させず、POSIX sh を基本とする。

## 変更ワークフロー

エージェントと通常のリポジトリ作業では、`home/` のソースを直接編集する。

1. 対象の source path と target path を確認する
2. `home/` 以下を編集する
3. `chezmoi diff` または隔離テストでレンダリング結果を確認する
4. `make check` を実行する
5. 一つの責務ごとにコミットする

実体側をアプリが更新した場合に限り、`chezmoi re-add <target>` で対象を限定して取り込む。引数なしの `chezmoi re-add`、自動的な `git add -A`、自動 commit/push は行わない。

コミットには、bootstrap、依存一覧、個別アプリ設定、ドキュメントなど、レビュー可能な一つの意図だけを含める。生成キャッシュや無関係なローカル変更を混ぜない。

## mise の更新

グローバルに常用するツールだけを `home/dot_config/mise/config.toml` に置く。言語は互換性を意識した明示バージョンを基本とし、ポータブル CLI は mise registry の標準バックエンドを利用する。

```sh
# 設定を編集した後
chezmoi apply ~/.config/mise/config.toml
mise install
mise doctor
```

mise bootstrap のバージョンを上げる場合は、`run_once_` は既存マシンで再実行されないことに注意する。既存マシンの mise 更新方法も同じコミットで明示するか、必要なら `run_onchange_` へ設計を変更する。

## OS パッケージの更新

macOS は Brewfile、Debian 系 Linux は一行一パッケージの一覧を変更する。次回 `chezmoi apply` で対応する `run_onchange_` が実行される。アンインストールは自動化されないため、一覧から削除したパッケージが不要なら、影響を確認して明示的に削除する。

Linux は現在 apt のみ対応する。他のディストリビューションを加える場合は、既存分岐を暗黙に流用せず、マニフェストとテスト方針を追加する。

## 検証

`make check` は以下を行う。

- sh/bash と fish の構文確認
- shellcheck が利用可能なら静的解析
- 一時 HOME に対する `chezmoi init`, `apply`, `verify`
- 実行権限、シンボリックリンク、除外ファイルの基本検証
- whitespace error の確認

テストでは scripts を除外し、パッケージ導入や実 HOME の変更、ネットワークアクセスを発生させない。bootstrap script 自体はレンダリング後の構文を lint する。

変更後の手動確認には次も利用する。

```sh
chezmoi execute-template < home/<template>
chezmoi apply --dry-run --verbose --exclude=scripts
chezmoi ignored
chezmoi doctor
mise doctor
```

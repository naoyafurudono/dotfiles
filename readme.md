# dotfiles

chezmoi で設定ファイルを配置し、mise で言語ランタイムとポータブルな CLI を管理する dotfiles リポジトリです。

## セットアップ

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- \
  init --apply https://github.com/naoyafurudono/dotfiles.git
```

初回実行時にマシン種別を入力します。その後、chezmoi が次の順序でセットアップします。

1. 固定バージョンの mise を `~/.local/bin` に導入する
2. macOS では Brewfile、Debian 系 Linux では apt の一覧からシステムパッケージを導入する
3. dotfiles を配置する
4. mise のグローバルツールを導入する

システムパッケージの導入では、ネットワーク接続や `sudo` の入力が必要になる場合があります。

## 日常操作

```sh
# 適用前の確認
chezmoi diff

# 適用
chezmoi apply

# リポジトリ全体の検証
make check
```

設定は原則として `home/` 以下の chezmoi ソースを編集します。対象ファイルだけを対話的に編集する場合は、次も利用できます。

```sh
chezmoi edit --apply ~/.config/fish/config.fish
```

アプリが実体側を書き換える設定を取り込む場合は、対象を必ず限定します。

```sh
chezmoi re-add ~/.config/zed/settings.json
```

引数なしの `chezmoi re-add` は、キャッシュやマシン固有値を意図せず取り込む可能性があるため使用しません。

## 新しいファイルの追加

```sh
chezmoi add ~/.config/<path>
```

追加後は `chezmoi diff` と `make check` で、秘密情報・ランタイムデータ・マシン固有の絶対パスが含まれていないことを確認してください。

詳細な責務分担、ファイル配置、更新手順は [管理方針](docs/management-policy.md) を参照してください。

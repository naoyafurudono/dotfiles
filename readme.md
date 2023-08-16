# dotfiles

## インストール

gitをあらかじめインストールしてください。

```sh
git clone https://github.com/naoyafurudono/dotfiles.git
bash dotfiles/setup.sh
```

## TODO

- [ ] gitのインストールを自動化
- [ ] テストの実施・自動テストの整備
  - [x] コンテナ環境で手動テストを実施 (ubuntu)
  - [ ] コンテナ環境で手動テストを実施 (mac os)
  - [x] 自動テストを実施 (ubuntu)
  - [ ] 自動テストを実施 (mac os)
  - [ ] CIを設定する

## 設定の追加

`.gitignore`をおしゃれに記述することで、ブラックリストではなくホワイトリストとして運用している。
リポジトリに追加したければ`.gitignore`を雰囲気で編集すること。

参考: <https://qiita.com/sventouz/items/574bd67c7e43fff10546>

## test

setup.shのテスト。
今はarmのubuntuだけ。
実際に動かして正常終了するかをみる。
それぞれのコマンドが動くかは見ていない。

```sh
cd test
docker build . -t test && \
docker run --rm test
```


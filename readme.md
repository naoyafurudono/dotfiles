# dotfiles

```
git clone https://github.com/naoyafurudono/dotfiles.git
bash dotfiles/setup.sh
```

`.gitignore`をおしゃれに記述することで、ブラックリストではなくホワイトリストとして運用している。
リポジトリに追加したければ`.gitignore`を雰囲気で編集すること。

参考: <https://qiita.com/sventouz/items/574bd67c7e43fff10546>

We manage nvim extentions throug git submodule.
Run following to install nvim extentions.

```sh
git submodule init
git submodule update
```

- TODO perform above in setup.sh

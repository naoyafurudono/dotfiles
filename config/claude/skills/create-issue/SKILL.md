---
name: create-issue
description: GitHub Issue を作成する。colorme org のリポジトリではチームタスクボードへの登録・assignee・Status 設定まで行う。トリガー例：「issue作って」「issue立てて」「issueにして」「イシュー作成」。
---

# create-issue

`gh issue create` で issue を作成し、colorme org ならプロジェクトボード登録までワンセットで行うスキル。

## カレント issue ファイル

いま触っている issue は `~/.claude/state/current-issues.md` に保持する（1 行 1 issue、新しいものを先頭に）：

```
- <URL> 「タイトル」 (親: <URL> or なし) <YYYY-MM-DD>
```

- 親 issue の推定や、後続セッションでの文脈復元に使う
- このスキルで issue を作成したら必ず先頭に追記する
- 古い行（クローズ済み・1ヶ月以上前）は見つけたら削除してよい

## 実行手順

### 1. 親 issue の特定

大体の issue には親（上位タスク・元となる issue）があるはずなので、以下の順で特定する：

a. ユーザーが明示した issue
b. 会話の文脈で扱っている issue
c. `~/.claude/state/current-issues.md` の先頭付近のエントリ

候補が見つかったら「親は <URL> 「タイトル」 でよいか」を作成前に確認する（自明な場合は確認不要）。どうしても見つからなければ親なしで作成してよいが、その旨を報告する。

### 2. issue 作成

- タイトル・本文をユーザーの依頼内容から組み立てる。本文には背景・やること・完了条件を書く
- 親 issue がある場合は本文の冒頭に `親issue: <URL> 「タイトル」` を記載する（URL を書けば親側のタイムラインにも参照が表示される）
- `gh issue create --title <title> --body <body>` で作成
- git.pepabo.com のリポジトリはリポジトリ内で実行すれば host が自動解決される。解決しない場合は `GH_HOST=git.pepabo.com` を付ける
- 作成後、カレント issue ファイルの先頭に追記する

### 3. プロジェクトボード登録（colorme org の issue のみ）

**hook が自動で行うので、自分では実行しない。** colorme org で `gh issue create` が成功すると、PostToolUse hook（`~/.config/claude/hooks/colorme-board-register.sh`）がチームタスクボード（project 123）への登録・Status=Backlog 設定・assignee(donokun) 設定を実行し、結果を additionalContext で報告してくる。

自分で操作するのは以下の場合のみ：

- hook が失敗を報告した場合、または完了報告が来ない場合の手動登録:
  `~/.config/claude/hooks/colorme-board-register.sh <Issue URL>`
- 「すぐ着手する」等の指示で Backlog 以外にしたい場合:
  `~/.config/claude/hooks/colorme-board-register.sh <Issue URL> <backlog|ready|in-progress|in-review|done>`
- `gh project` の権限エラー時は `gh auth refresh -h git.pepabo.com -s project` を案内する

### 4. 報告

- Issue URL を `<URL> 「<タイトル>」` の形式で報告する
- 親 issue を `<URL> 「<タイトル>」` の形式で報告する（親なしで作成した場合はその旨）
- colorme org の issue はボード登録・assignee・Status 設定を行ったことを報告する

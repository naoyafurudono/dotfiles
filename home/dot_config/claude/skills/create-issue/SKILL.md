---
name: create-issue
description: GitHub Issue を作成する。colorme org のリポジトリではチームタスクボードへの登録・assignee・Status 設定まで行う。トリガー例：「issue作って」「issue立てて」「issueにして」「イシュー作成」。
---

# create-issue

`gh issue create` で issue を作成し、colorme org ならプロジェクトボード登録までワンセットで行うスキル。

## 実行手順

### 1. issue 作成

- タイトル・本文をユーザーの依頼内容から組み立てる。本文には背景・やること・完了条件を書く
- `gh issue create --title <title> --body <body>` で作成
- git.pepabo.com のリポジトリはリポジトリ内で実行すれば host が自動解決される。解決しない場合は `GH_HOST=git.pepabo.com` を付ける

### 2. プロジェクトボード登録（colorme org の issue のみ）

git.pepabo.com の colorme org リポジトリで issue を作成した場合は、必ずチームタスクボードに登録し assignee を設定する：

```
GH_HOST=git.pepabo.com gh project item-add 123 --owner colorme --url <Issue URL> --format json  # 返却 JSON の id を控える
GH_HOST=git.pepabo.com gh issue edit <番号> --add-assignee donokun
```

さらに Status フィールドを設定する（ID は project 123 で固定）。デフォルトは **Backlog**。すぐ着手する等の指示があれば適切なステータスを選ぶ：

```
PROJ_ID=$(GH_HOST=git.pepabo.com gh project view 123 --owner colorme --format json | jq -r .id)
GH_HOST=git.pepabo.com gh project item-edit --id <item-addのid> --project-id $PROJ_ID \
  --field-id MDI2OlByb2plY3RWMlNpbmdsZVNlbGVjdEZpZWxkNDkzNw== --single-select-option-id f75ad846
```

- Status オプション ID: Backlog=f75ad846, Ready=50380717, In Progress=47fc9ee4, In Review=c39c9d61, Done=98236657
- assignee 設定はボードの `sliceBy=donokun` で表示させるために必要
- `gh project` にはスコープ `read:project`/`project` が必要。権限エラーの場合は `gh auth refresh -h git.pepabo.com -s project` を案内する

### 3. 報告

- Issue URL を `<URL> 「<タイトル>」` の形式で報告する
- colorme org の issue はボード登録・assignee・Status 設定を行ったことを報告する

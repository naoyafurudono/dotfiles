# hoocron: 要求整理

## 背景・動機

Claude Code のスキルやツールは使いっぱなしになりがちで、「出力品質が悪い」「引数の選び方が不適切」といった問題に気づく仕組みがない。使用ログを溜めても、分析のトリガーがないと改善サイクルが回らない。

WordPress の pseudo-cron（ユーザーリクエストに相乗りして定期処理を実行する仕組み）のように、Claude Code のセッションライフサイクルに相乗りして「条件を満たしたときだけ」分析・改善提案を発火させたい。

## 解決したい問題

**ツール/スキルの継続的改善に、人間のトリガーなしでフィードバックループを回す仕組みがない。**

具体例:

- session-recall スキルの検索精度が悪くても、誰も気づかない
- 使用ログは溜まるが、分析を誰かが手動で実行しないと活用されない
- 改善提案のタイミングが「ユーザーが思い出したとき」に依存する

## ユースケース

1. **使用ログの定期分析**: session-recall のログが N 件溜まったら自動で分析し、改善提案を stdout に出す
2. **品質メトリクスの監視**: ゼロヒット率、平均実行時間などが閾値を超えたらアラート
3. **一般的な定期処理**: 特定のスキルに限らず、任意の「条件付き定期処理」を Claude Code のフックに乗せたい

## 設計上の制約（Claude Code Hooks の仕様）

### 利用するフックイベント

- **`SessionStart`**: セッション開始時に発火。stdout が Claude のコンテキストに注入される。matcher は `startup | resume | clear | compact`
- **`Stop`**: Claude が応答を完了したときに発火。stdout が Claude のコンテキストに注入される

### フックの特性

- stdin に JSON ペイロードが渡される（session_id, cwd など）
- stdout → Claude のコンテキストに注入（SessionStart, Stop の場合）
- stderr → verbose モードでのみ表示
- exit 0 → 処理続行、exit 2 → ブロック
- タイムアウトはデフォルト 600 秒（設定可能）
- 複数フックは並列実行される

## ツールのインターフェース設計

### 核心的な問い

このツールは「どのフックイベントで」「何を条件に」「何を実行するか」を宣言的に定義するもの。

### 設計案: ジョブ定義ファイル

```yaml
# ~/.claude/cron/session-recall-analysis.yaml
name: session-recall-analysis
description: session-recall の使用ログを分析して改善提案を行う

# いつ実行するか
trigger:
  hook: SessionStart          # どのフックイベントに相乗りするか
  matcher: startup             # matcher（省略可）

# 実行条件（これを満たさなければ何も出力しない）
condition:
  type: lines-since-last-run   # 前回実行時からの行数増分
  file: ~/.claude/usage/session-recall.tsv
  threshold: 30

# 何を実行するか
action:
  command: ~/.claude/cron/scripts/analyze-session-recall.sh
  # stdout → Claude のコンテキストに注入される
  # 条件を満たさなかった場合は何も出力しない（コンテキスト汚染を防ぐ）
```

### ランナー（フックに登録するコマンド）

```bash
# ランナーは1つだけ。全ジョブ定義を読み込んで、条件を満たすものだけ実行する
hoocron run --hook=SessionStart --matcher=startup
```

これを Claude Code の settings.json に1行登録するだけで動く:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "hoocron run --hook=SessionStart --matcher=startup"
          }
        ]
      }
    ]
  }
}
```

### ランナーの責務

1. `~/.claude/cron/*.yaml` を読み込む
2. 現在のフックイベント・matcher に該当するジョブを絞り込む
3. 各ジョブの condition を評価（前回実行からのログ行数、経過時間など）
4. 条件を満たすジョブの action を実行
5. action の stdout をそのまま出力（→ Claude のコンテキストに注入）
6. 条件を満たさなかったジョブは何も出力しない
7. 前回実行のタイムスタンプ/状態を `~/.claude/cron/state/` に保存

### condition の種類（初期実装の候補）

| type                   | 説明                                          | パラメータ          |
| ---------------------- | --------------------------------------------- | ------------------- |
| `lines-since-last-run` | ファイルの行数が前回実行時から N 行以上増えた | `file`, `threshold` |
| `time-since-last-run`  | 前回実行から N 時間以上経過した               | `hours`             |
| `file-changed`         | 指定ファイルが前回実行時から変更された        | `file`              |
| `always`               | 常に実行（デバッグ用）                        | なし                |

### 出力の原則

- **条件を満たさない → 何も出力しない**（コンテキスト汚染ゼロ）
- **条件を満たす → action の stdout をそのまま出力**
- action スクリプトは「Claude が読んで改善提案に繋げられる」テキストを出力する責務を持つ

## 実装言語

シェルスクリプト（bash）。依存を最小にして、どの環境でも動くようにする。

## ファイル構成案

```
hoocron/
├── hoocron              # メインランナースクリプト (bash)
├── README.md
├── examples/
│   └── session-recall-analysis.yaml
└── scripts/
    └── (ユーザーが自分の分析スクリプトを置く場所の例)
```

## 未決事項

- [ ] ジョブ定義のフォーマット: YAML vs TOML vs JSON vs シェルスクリプト自体
  - YAML は bash で扱いにくい。JSON なら jq で処理可能
  - シェルスクリプト自体に条件をハードコードする方がシンプルかもしれない
- [ ] 複数フックイベントへの登録: ランナーを各イベントに登録する vs 1つのフックで全イベントを処理する
- [ ] condition の拡張性: プラグイン的に追加できるようにするか、初期は固定か
- [ ] state の保存場所とフォーマット

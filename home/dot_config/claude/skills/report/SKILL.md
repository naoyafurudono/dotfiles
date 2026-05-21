---
name: report
description: |
  Typstを用いてまとまった文書（レポート、ガイド、調査報告等）を作成するスキル。
  CS論文のフォーマットに則り、積極的に図を用いて構造化された文書を生成する。
  ユーザーが「レポートを書いて」「まとめて文書にして」「体系的に説明して」
  「ガイドを作って」「調査結果を整理して」などを依頼したときにトリガーされます。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# レポート作成スキル

Typst を用いて文書を作成し、PDF を生成する。

## 文書構成

CS論文のフォーマットに従う:

1. **タイトル・著者・日付** — 著者は Claude をファーストオーサー、ユーザーをセカンドオーサーとする
2. **概要（Abstract）** — 文書全体の要約を3〜5文で
3. **はじめに（Introduction）** — 背景、目的、文書の構成
4. **本論** — セクションに分割。各セクションは1つの主張やトピックに集中する
5. **まとめ（Conclusion）** — 知見の要約、今後の課題
6. **参考文献** — Typst の `bibliography()` を使うか、簡易なら手書きリスト + `#link()` でクリッカブルにする

## 図の活用

積極的に図を使って説明を補強する。図の描画は以下を使う:

- 一般的な図形・矢印・ノード: `cetz` パッケージ（`#import "@preview/cetz:0.4.2"`）
- フローチャート・ダイアグラム: `fletcher` パッケージ（`#import "@preview/fletcher:0.5.9": diagram, node, edge`）

使いどころ:

- プロセスフロー・ワークフロー
- システム構成・アーキテクチャ
- 比較表では伝わりにくい関係性
- タイムライン・段階の可視化

すべての図は `#figure(..., caption: [...]) <label>` で配置し、本文から `@label` で参照する。

## Typst テンプレート

```typst
#set document(title: "タイトル", author: ("Claude (Anthropic)", "ユーザー名"))
#set page(paper: "a4", margin: 25mm, numbering: "1")
#set text(font: ("Hiragino Mincho ProN",), lang: "ja", size: 11pt)
#show heading: set text(font: ("Hiragino Kaku Gothic ProN",))
#set par(justify: true, leading: 0.8em)
#show link: set text(fill: blue)

#align(center)[
  #text(size: 18pt, weight: "bold")[タイトル] \
  #v(0.5em)
  Claude (Anthropic) #h(1em) ユーザー名 \
  #datetime.today().display("[year]-[month]-[day]")
]

#align(center)[*概要*] \
ここに要約を3〜5文で書く。

= はじめに
背景・目的・構成。

= 本論
内容。図は次のように:

#figure(
  image("fig.svg"),
  caption: [図のキャプション],
) <fig-overview>

@fig-overview を参照する。

= まとめ
要約と今後の課題。

#bibliography("refs.bib")  // 必要なときのみ
```

注意点:

- 日本語フォントは macOS のヒラギノを指定する
- パッケージは `#import "@preview/<name>:<version>"` で自動取得される
- 見出しは `= / == / ===` で階層表現

## ビルドと確認

```bash
typst compile file.typ
```

- 1コマンドで PDF が生成される
- パッケージは初回に自動ダウンロードされる
- typ ファイルを作成・変更したら、必ずビルドが通ることを確認する
- ビルド後、`open file.pdf` でPDFを開いてユーザーに確認してもらう
- 執筆中に継続的にプレビューしたい場合は `typst watch file.typ`

## 作業の流れ

1. ユーザーの要求からテーマと目的を明確にする
2. 文書のアウトライン（セクション構成）を提示して合意を得る
3. Typst ファイルを作成する
4. `typst compile` でビルドする
5. レンダリング結果が読みやすいことを確認する。読みやすくなるまで修正する。特に図表が意図を明らかに説明するようになっていることを担保する

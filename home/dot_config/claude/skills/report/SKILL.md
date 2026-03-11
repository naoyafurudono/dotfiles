---
name: report
description: |
  TeXを用いてまとまった文書（レポート、ガイド、調査報告等）を作成するスキル。
  CS論文のフォーマットに則り、積極的に図を用いて構造化された文書を生成する。
  ユーザーが「レポートを書いて」「まとめて文書にして」「体系的に説明して」
  「ガイドを作って」「調査結果を整理して」などを依頼したときにトリガーされます。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# レポート作成スキル

Tectonicを用いてTeX文書を作成し、PDFを生成する。

## 文書構成

CS論文のフォーマットに従う:

1. **タイトル・著者・日付**
2. **概要（Abstract）** — 文書全体の要約を3〜5文で
3. **はじめに（Introduction）** — 背景、目的、文書の構成
4. **本論** — セクションに分割。各セクションは1つの主張やトピックに集中する
5. **まとめ（Conclusion）** — 知見の要約、今後の課題
6. **参考文献** — 参照した資料を列挙

## 図の活用

積極的に図を使って説明を補強する。TikZで直接描画する。

使いどころ:

- プロセスフロー・ワークフロー
- システム構成・アーキテクチャ
- 比較表では伝わりにくい関係性
- タイムライン・段階の可視化

```tex
\usepackage{tikz}
\usetikzlibrary{arrows.meta, positioning, shapes.geometric}
```

すべての図には `\caption` と `\label` を付け、本文から `\ref` で参照する。

## TeX テンプレート

処理系は **Tectonic** を使う。LuaTeX-ja（`ltjsarticle`, `luatexja`）は使えない。

```tex
\documentclass[a4paper,11pt,xelatex,ja=standard]{bxjsarticle}
\usepackage{xeCJK}
\setCJKmainfont{Hiragino Mincho ProN}
\setCJKsansfont{Hiragino Kaku Gothic ProN}
\geometry{margin=25mm}
\usepackage{hyperref}
\usepackage{booktabs}
\usepackage{enumitem}
\usepackage{longtable}
\usepackage{tikz}

\hypersetup{
  colorlinks=true,
  linkcolor=blue,
  citecolor=blue,
  urlcolor=blue
}
```

注意点:

- `bxjsarticle` が内部で `geometry` を読み込むため、`\usepackage[...]{geometry}` ではなく `\geometry{...}` を使う
- フォントはmacOSのヒラギノを指定する

## ビルドと確認

```bash
tectonic file.tex
```

- 1コマンドでPDFが生成される（目次・相互参照の再実行も自動）
- パッケージは自動ダウンロードされるため `tlmgr install` は不要
- 中間ファイルは残らない
- texファイルを作成・変更したら、必ずビルドが通ることを確認する
- ビルド後、`open file.pdf` でPDFを開いてユーザーに確認してもらう

## 作業の流れ

1. ユーザーの要求からテーマと目的を明確にする
2. 文書のアウトライン（セクション構成）を提示して合意を得る
3. TeXファイルを作成する
4. `tectonic` でビルドする
5. レンダリング結果がユーザにとって読みやすいものあることを確認する。読みやすくなるまで修正する。特に図表が意図を明らかに説明するようになっていることを担保する

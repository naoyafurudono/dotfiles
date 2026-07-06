---
name: colorme-blacklist-add-ip
description: カラーミーのアカウント登録ブロックリスト（colorme-www `app/configs/blacklist.yml`）に個別IPを追加する。ブランチ作成→yml追記→重複/形式チェック→コミット→draft PR 作成までを行う。トリガー例：「ブラックリストにIP追加して」「signup IP block」「colorme blacklist」「カラーミー 登録 IP ブロック」。
---

# colorme-blacklist-add-ip

カラーミーのショップ申込フォームでスパム/不正登録をブロックするため、`colorme/colorme-www` リポジトリの `app/configs/blacklist.yml` に IPv4 アドレスを追加し、draft PR を作成するスキル。

## 背景（追加先の選定理由）

- 申込時の IP ベース拒否は `Order_Entry_Model::isSpammer()` → `Blacklist::isListedIp()` で行われ、判定は `app/configs/blacklist.yml` の `ip:` 配列を参照する
- DNSBL (`bl.spamcop.net` 等) と並列の静的ブロック層
- CIDR は非対応（完全一致のみ）。CIDR が必要な要件が出たら `Blacklist` クラスの拡張が別途必要

このスキルは「個別 IPv4 を即時追加して塞ぐ」用途に限定する。CIDR/国コード/ASN などの動的判定が必要ならこのスキルでは対応せず、設計から相談すること。

## 受け取る入力

- **IP アドレス**: IPv4 を 1〜複数。空白・カンマ・改行のいずれかで区切られていてよい
- **追加理由**: 1〜2 行。可能なら原因の Slack URL や Issue URL を 1 つ含める
- **緊急度**（任意）: 通常 / 緊急。緊急の場合は PR 説明文にその旨を明記

不足があれば AskUserQuestion で補う。

## 実行手順

1. リポジトリの確認
   - `~/src/git.pepabo.com/donokun/memo/colorme/repos/colorme-www`
   - 無ければ `GH_HOST=git.pepabo.com gh repo clone colorme/colorme-www repos/colorme-www` でクローン
   - `git status` で uncommitted があれば中断してユーザーに確認
   - `git fetch origin && git checkout master && git pull --rebase origin master`

2. 入力の検証（追加スクリプトを使う）
   - `python3 ~/.claude/skills/colorme-blacklist-add-ip/add_ips.py --check IP1 IP2 ...` で
     - IPv4 形式の妥当性
     - `app/configs/blacklist.yml` 既存リストとの重複（重複は警告して無視）
   - 無効 IP があれば中断してユーザーに報告

3. ブランチ作成
   - `git switch -c add-blacklist-ip-$(date +%Y%m%d-%H%M)`

4. `app/configs/blacklist.yml` への追記
   - `python3 ~/.claude/skills/colorme-blacklist-add-ip/add_ips.py --apply IP1 IP2 ...` を実行
   - スクリプトは既存の `ip:` 配列に追記し、**ファイル全体の `ip:` 配列を辞書順で再ソート**して書き戻す（既存ファイルは辞書順で並んでいる）
   - `email:` セクションは触らない

5. 検証
   - `git diff app/configs/blacklist.yml` を読み、追加行のみ差分になっていることを確認
   - 既存 `tests/app/libs/cmsp/BlacklistTest.php` を可能なら実行：
     - `make dev/test` あるいは `docker compose run --rm www-php-fpm /bin/bash -c "cd tests && ../vendor/bin/phpunit app/libs/cmsp/BlacklistTest.php"`
     - 環境が立ち上がっていない場合は実行をスキップし、その旨を PR description に記す

6. コミット
   - メッセージは過去スタイルに合わせて日本語で簡潔に。例：
     - 単数: `ブラックリストに 1.2.3.4 を追加`
     - 複数: `ブラックリストに IP アドレスを追加 (N件)`
   - 末尾に `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`

7. push & draft PR 作成
   - `git push -u origin <branch>`
   - `gh pr create --draft` で作成（**`--reviewer` は付けない**。`gh-pr-guard` で強制されている）
   - PR タイトル: コミットメッセージと同じ
   - PR 本文テンプレ：

     ```
     ## 概要
     <理由 1〜2 行。Slack/Issue URL があれば併記>

     ## 追加した IP
     - 1.2.3.4
     - 5.6.7.8

     ## 追加先
     `app/configs/blacklist.yml` の `ip:` 配列。
     `Order_Entry_Model::isSpammer()` 経由でショップ申込時にブロックされる。

     ## テスト
     - [ ] BlacklistTest がパスすること（ローカルで未実行の場合はチェック外す）

     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     ```

8. ユーザーへ報告
   - PR URL を `https://git.pepabo.com/colorme/colorme-www/pull/<番号> 「<タイトル>」` の形式で出す
   - draft のままなので、ready 化はユーザー判断（`gh pr ready <番号>` を案内）

## 注意

- `blacklist.yml` は ASCII のみ（EUC-JP 変換の対象外）
- 大量追加（数百件以上）の場合はそもそも DB 化や別ソース化を検討すべきなので、件数が多いときはスキル実行前にユーザーへ方針確認
- VPN 越し・社内 NW・ペパボ管理 IP など「絶対に登録経路で来ない IP」を誤って入れない。スクリプトに「自社 IP らしきものは警告」までは入れていないので、追加前に IP の素性を一度確認する
- `Blacklist` クラスは完全一致のみ。`/24` 等のレンジ拒否要件はこのスキルでは扱わない

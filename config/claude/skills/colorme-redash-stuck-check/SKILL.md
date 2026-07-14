---
name: colorme-redash-stuck-check
description: カラーミーの Redash (https://redash.pepper.shop-pro.jp/) が「クエリが詰まった」状態か診断する。worker Pod の状態・ログ停止時刻・restart 回数を確認し、必要であれば README 記載の rollout restart を提案する。トリガー例：「redash 詰まった」「select 1 が返ってこない」「redash worker おかしい」「colorme redash 調子悪い」。
---

# colorme-redash-stuck-check

カラーミー Redash の調子が悪いとき（`SELECT 1` すら返らない、クエリがいつまでも終わらない、スケジュールクエリが動いていない 等）に worker 詰まりを切り分ける診断手順。

## 前提

- 対象クラスタ: `arn:aws:eks:ap-northeast-1:424060324797:cluster/colorme-production-v202506`
- 対象 namespace: **`default`**（`colorme-k8s/redash/README.md` には `redash` と書かれているが、現状は `default` で稼働。README は古い）
- 関連 Deployment（namespace=default）:
  - `redash-server-deployment`
  - `redash-worker-deployment` ← Celery worker / Beat。詰まりはここが大半
  - `redash-redis-deployment` ← ジョブキュー
  - `redash-postfix-deployment`
- worker は liveness probe で `vmstat` の swap(si+so) を監視。swap が出ると自動再起動される

## 実行してよいコマンド（allowlist）

このスキル中は **以下のコマンドのみ** を実行する。書き込み・実行・転送系の kubectl サブコマンド（apply / delete / exec / port-forward / rollout 等）は **絶対に呼ばない**。`rollout restart` は復旧手段だが、必ずユーザー確認後にユーザー自身に実行してもらう（このスキルでは打たない）。

read-only:

- `kubectl config current-context`
- `kubectl -n default get deploy`（grep redash で絞ってよい）
- `kubectl -n default get pods -l app=redash-worker -o wide`
- `kubectl -n default get pods -l app=redash-server -o wide`
- `kubectl -n default get pods -l app=redash-redis -o wide`
- `kubectl -n default top pods -l app=redash-worker`
- `kubectl -n default logs <pod-name> --tail=<N>`（N は 3〜200 程度）
- `kubectl -n default describe pod <pod-name>`（必要時のみ）

シェルは fish を想定。複数 Pod のループは:

```fish
for p in (kubectl -n default get pod -l app=redash-worker -o name)
    echo "=== $p ==="
    kubectl -n default logs $p --tail=3
end
```

許可リストに無い kubectl サブコマンドが必要になった場合は、実行せずユーザーに目的を説明し承認を得てから検討する。

## 診断手順

1. **コンテキスト確認**: `kubectl config current-context` が `colorme-production-v202506` を指していることを確認。違う場合は切り替えてもらう。
2. **Deployment の生存確認**: `kubectl -n default get deploy | grep -i redash` で `redash-{server,worker,redis,postfix}-deployment` が `READY=desired` か。
3. **Pod の状態**: `kubectl -n default get pods -l app=redash-worker -o wide`
   - `RESTARTS` が直近で増えている Pod は liveness 失敗（swap 発生）= 過負荷の兆候
   - 全 Pod が `Running` でも詰まりは起きうる（次の手順で確定する）
4. **リソース使用率**: `kubectl -n default top pods -l app=redash-worker`
   - CPU が limit(1737m) に張り付き / Memory が limit(2048M) 近辺 なら過負荷
5. **ログ最終タイムスタンプ（最重要）**: 各 worker pod で `--tail=3` を取り、最終行の時刻を見る。
   - 通常は Celery Beat が **数十秒おき** に `Sending due task refresh_queries` 等を出力する
   - 最終ログが数分〜数時間以上前なら **Beat / worker が hang している可能性が高い**＝詰まり確定の強い証拠
   - 例: 現在時刻 13:13 に対して最終ログが前日 21:24 → 約 16 時間停止 → 詰まり確定
6. **判定**:
   - 詰まりあり: 復旧手順を提示（後述）
   - 詰まりなし: server / redis 側、データソース側（select 1 すら返らないならデータソース DB が落ちている可能性）を疑う。`kubectl -n default get pods -l app=redash-server` と server ログも確認する

## 復旧手順（ユーザーが実行）

詰まりが確定したら、以下をユーザーに案内する。**スキル側では実行しない**（rollout は deny されており、また再起動は副作用があるため）。

```
kubectl -n default rollout restart deployment/redash-worker-deployment
```

注意:

- namespace は `redash` ではなく `default`（README は要更新）
- 実行中の adhoc クエリは打ち切られる旨を周知してから実行するのが望ましい
- 再起動後 1〜2 分で Beat ログが再開するか `kubectl -n default logs ... --tail=5` で確認

## 出力の型

ユーザーへの最終報告には以下を含める。

- 各 worker Pod の Restarts と最終ログ時刻（経過時間付き）
- top の CPU / Memory
- 詰まり判定（YES/NO とその根拠）
- 推奨アクション（rollout restart コマンド or 他の切り分けポイント）

## 参考

- `colorme/repos/colorme-k8s/redash/README.md`（FAQ「クエリが詰まった」）
- worker の livenessProbe は vmstat の swap で詰まり検知している（`redash-worker-deployment` の manifest 参照）

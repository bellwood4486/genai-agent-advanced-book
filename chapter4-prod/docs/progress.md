# 構築進捗チェックリスト

テスト実行コマンドは `deployment-plan.md` の各Incrementを参照。
- Unit: `uv run pytest tests/unit/ -v`
- Integration: `uv run pytest tests/integration/ -v`
- E2E: `uv run pytest tests/e2e/ -v`

---

## Step 0: 前提準備
- [ ] GCPプロジェクト作成
- [ ] 課金アカウントリンク + 課金アラート設定（$10, $25, $50）
- [ ] `gcloud auth application-default login`
- [ ] Terraform インストール
- [ ] Terraform state用GCSバケット作成（バージョニング有効）
- [ ] Elastic Cloudアカウント作成 + APIキー取得
- [ ] Qdrant Cloudアカウント作成 + APIキー取得
- [ ] GitHub Secretsにサービスアカウントキー登録（GCP認証用）

## Increment 1: プロジェクト雛形 + 設定リファクタ
- [ ] chapter4から`src/`, `data/`, `pyproject.toml`, `uv.lock`等をコピー
- [ ] `src/configs.py`に`elasticsearch_url`, `qdrant_url`, `qdrant_api_key`追加
- [ ] `src/tools/search_xyz_manual.py`のlocalhost→Settings経由に変更
- [ ] `src/tools/search_xyz_qa.py`のlocalhost→Settings経由に変更
- [ ] Terraform `infra/`ディレクトリ構造作成（スケルトン）
- [ ] `pytest tests/unit/test_configs.py` 全通過
- [ ] `terraform validate` 成功
- [ ] `.github/workflows/chapter4-prod-ci.yml`作成（lint + unit test、devへのPR/push時）

## Increment 2: FastAPI + Dockerfile
- [ ] `fastapi`, `uvicorn`を依存に追加
- [ ] `src/main.py`作成（`GET /health`, `POST /v1/chat`）
- [ ] `Dockerfile`作成（マルチステージビルド）
- [ ] `.dockerignore`作成
- [ ] `pytest tests/unit/test_main.py` 全通過
- [ ] Dockerビルド成功
- [ ] `pytest tests/integration/test_api_local.py` 全通過
- [ ] `.github/workflows/chapter4-prod-deploy.yml`作成（Docker build & push to Artifact Registry、devへのmerge時）

## Increment 3: Elastic Cloud Serverless + Qdrant Cloud（Terraform）
- [ ] `modules/elastic-cloud/` — `ec_elasticsearch_project`定義
- [ ] `modules/qdrant-cloud/` — Free Tierクラスタ定義
- [ ] `terraform apply` 成功
- [ ] `pytest tests/integration/test_search_cloud.py` 全通過（ES/Qdrant接続・インデックス作成・検索確認）

## Increment 4: GCP基盤（Terraform）
- [ ] GCP API有効化（run, secretmanager, artifactregistry）
- [ ] `modules/networking/` — VPC + サブネット定義
- [ ] `modules/secret-manager/` — APIキー群を登録
- [ ] `modules/artifact-registry/` — Dockerリポジトリ定義
- [ ] Cloud Run用サービスアカウント + IAM設定
- [ ] `terraform apply` 成功
- [ ] Artifact Registryへのdocker push疎通確認
- [ ] `.github/workflows/chapter4-prod-tf-plan.yml`作成（`infra/`変更のPR時にterraform planをコメント出力）

## Increment 5: Cloud Runデプロイ（MVP）⭐
- [ ] `modules/cloud-run/` — v2 service定義
- [ ] アプリイメージをArtifact Registryにpush
- [ ] `terraform apply` 成功
- [ ] `pytest tests/e2e/test_cloud_run.py` 全通過（ヘルスチェック + 実際の質問への回答）

## Increment 6: GCS + Cloud Run Jobs（インデックス作成パイプライン）
- [ ] `modules/storage/` — GCSバケット定義
- [ ] `modules/ingestion/` — Cloud Run Job定義
- [ ] `google-cloud-storage`を依存に追加
- [ ] `create_index.py`をGCS読み取り対応にリファクタ
- [ ] `terraform apply` 成功
- [ ] `pytest tests/integration/test_ingestion.py` 全通過（GCSアップロード → Job実行 → インデックス確認）

## Increment 7: Eventarc自動トリガー
- [ ] `google_eventarc_trigger`定義（GCS finalized → Cloud Run Job）
- [ ] Eventarc用IAM設定
- [ ] インデックス作成ジョブをイベントペイロード対応に変更
- [ ] `terraform apply` 成功
- [ ] `pytest tests/e2e/test_eventarc.py` 全通過（GCSアップロード → 自動実行 → インデックス確認）

## Increment 8: Firestore会話履歴
- [ ] `modules/firestore/` — database定義
- [ ] `google-cloud-firestore`を依存に追加
- [ ] `src/store.py`作成
- [ ] FastAPIエンドポイント追加（`GET /v1/conversations`等）
- [ ] `pytest tests/unit/test_store.py` 全通過
- [ ] `terraform apply` 成功
- [ ] `pytest tests/integration/test_firestore.py` 全通過

## Increment 9: Observability
- [ ] `modules/observability/` — アラートポリシー + 通知チャネル定義
- [ ] 構造化JSONログ導入（`python-json-logger`）
- [ ] OpenTelemetry導入（Cloud Trace連携）
- [ ] リクエストIDミドルウェア追加
- [ ] `pytest tests/unit/test_log_format.py` 全通過
- [ ] `terraform apply` 成功
- [ ] Cloud Loggingでリクエストに紐づく構造化ログが確認できる

## Increment 10（オプション）: Global LB + Cloud Armor
- [ ] Serverless NEG + Backend Service + URL Map + HTTPS Proxy定義
- [ ] Cloud Armorセキュリティポリシー定義（レート制限 + OWASP）
- [ ] Cloud Run ingressを`internal-and-cloud-load-balancing`に変更
- [ ] `terraform apply` 成功
- [ ] `pytest tests/e2e/test_lb.py` 全通過（LB経由アクセス + 429レート制限確認）

## Increment 11（オプション）: SSEストリーミング
- [ ] `POST /v1/chat/stream`エンドポイント追加
- [ ] `graph.astream()`でイベントストリーム実装
- [ ] `pytest tests/unit/test_main.py::test_chat_stream` 通過
- [ ] `pytest tests/e2e/test_cloud_run.py::test_chat_stream` 通過

# 構築進捗チェックリスト

テスト実行コマンドは `deployment-plan.md` の各Incrementを参照。
- Unit: `uv run pytest tests/unit/ -v`
- Integration: `uv run pytest tests/integration/ -v`
- E2E: `uv run pytest tests/e2e/ -v`

---

## Step 0: 前提準備
- [x] GCPプロジェクト作成（`genai-book-ch4-helpdesk`）
- [x] 課金アカウントリンク + 課金アラート設定（$10, $25, $50）
- [x] `gcloud auth application-default login`
- [x] Terraform インストール（`brew install terraform`）
- [x] Terraform state用GCSバケット作成（`genai-book-ch4-helpdesk-tfstate`、バージョニング有効）
- [x] Elastic Cloudアカウント作成 + APIキー取得
- [x] Qdrant Cloudアカウント作成 + APIキー取得
- [x] GitHub Secretsにサービスアカウントキー登録（`GCP_SA_KEY`）← Increment 4で対応
- [x] GitHub Variables登録（`AR_REGION=asia-northeast1`, `GCP_PROJECT_ID`）← Increment 4で対応

## Increment 1: プロジェクト雛形 + 設定リファクタ
- [x] chapter4から`src/`, `data/`, `pyproject.toml`, `uv.lock`等をコピー
- [x] `src/configs.py`に`elasticsearch_url`, `qdrant_url`, `qdrant_api_key`追加
- [x] `src/tools/search_xyz_manual.py`のlocalhost→Settings経由に変更
- [x] `src/tools/search_xyz_qa.py`のlocalhost→Settings経由に変更
- [x] `src/scripts/create_index.py`のlocalhost→Settings経由に変更（重複Settingsクラスも削除）
- [x] `src/scripts/delete_index.py`のlocalhost→Settings経由に変更
- [x] Terraform `infra/`ディレクトリ構造作成（スケルトン）
- [x] `chapter4-prod/CLAUDE.md`作成（コマンド体系・Terraform規約・テスト実行方法）
- [x] ルート`CLAUDE.md`にchapter4-prodセクション追加
- [x] `.gitignore`作成（`.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars` + Python標準）
- [x] `Makefile`作成（`test-unit`, `test-integration`, `test-e2e`, `plan`, `apply`, `deploy` 等）
- [x] `pytest tests/unit/test_configs.py` 全通過（5/5）
- [x] `terraform validate` 成功
- [x] `.github/workflows/chapter4-prod-ci.yml`作成（lint + unit test、devへのPR/push時）

## Increment 2: FastAPI + Dockerfile
- [x] `fastapi`, `uvicorn`を依存に追加
- [x] `src/main.py`作成（`GET /health`, `POST /v1/chat`）
- [x] `Dockerfile`作成（マルチステージビルド）
- [x] `.dockerignore`作成
- [x] `pytest tests/unit/test_main.py` 全通過（4/4）
- [x] Dockerビルド成功
- [ ] `pytest tests/integration/test_api_local.py` 全通過
- [x] `.github/workflows/chapter4-prod-deploy.yml`作成（Docker build & push to Artifact Registry、devへのmerge時）

## Increment 3: Elastic Cloud Serverless + Qdrant Cloud（Terraform）
- [x] `modules/elastic-cloud/` — `ec_elasticsearch_project`定義
- [x] `modules/qdrant-cloud/` — Free Tierクラスタ定義
- [x] `terraform apply` 成功
- [x] `pytest tests/integration/test_search_cloud.py` 全通過（ES/Qdrant接続・インデックス作成・検索確認）

## Increment 4: GCP基盤（Terraform）
- [x] GCP API有効化（run, secretmanager, artifactregistry, compute）
- [x] `modules/networking/` — VPC + サブネット定義
- [x] `modules/secret-manager/` — APIキー群を登録
- [x] `modules/artifact-registry/` — Dockerリポジトリ定義
- [x] Cloud Run用サービスアカウント + IAM設定
- [x] `terraform apply` 成功
- [x] Artifact Registryへのdocker push疎通確認
- [x] `.github/workflows/chapter4-prod-tf-plan.yml`作成（`infra/`変更のPR時にterraform planをコメント出力）
- [x] GitHub Variables登録（`AR_REGION`, `GCP_PROJECT_ID`）← Deploy CI修正に必要

## Increment 5: Cloud Runデプロイ（MVP）⭐
- [x] `modules/cloud-run/` — v2 service定義
- [x] `src/configs.py` に `elastic_username` / `elastic_api_key` 追加（Elastic Cloud Serverless Basic認証対応）
- [x] アプリイメージをArtifact Registryにpush（`--platform linux/amd64 --provenance=false`）
- [x] `terraform apply` 成功
- [x] `pytest tests/e2e/test_cloud_run.py` 全通過（ヘルスチェック + 実際の質問への回答）

## Increment 6: GCS + Cloud Run Jobs（インデックス作成パイプライン）
- [x] `modules/storage/` — GCSバケット定義
- [x] `modules/ingestion/` — Cloud Run Job定義
- [x] `google-cloud-storage`を依存に追加
- [x] `create_index.py`をGCS読み取り対応にリファクタ
- [x] `terraform apply` 成功
- [x] `pytest tests/integration/test_ingestion.py` 全通過

### テスト分離対応（追加）
- [x] `src/configs.py` に `index_name` 追加（`INDEX_NAME` env、デフォルト `"documents"`）
- [x] `create_index.py` / `delete_index.py` / 検索ツール2本を `settings.index_name` 対応
- [x] `create_index.py` に `--index-name` CLI 引数追加（argparse）
- [x] `test_ingestion.py` をテスト専用インデックス名（`test-documents-<uuid>`）で実行するよう変更（`--args` で Job に渡す）
- [x] `delete_index.py` の Qdrant ハードコードバグ修正
- [x] `pytest tests/integration/test_ingestion.py` 全通過（本番 `documents` インデックス非破壊を確認）
- [x] `pytest tests/e2e/test_cloud_run.py` 全通過（テスト後も Cloud Run Service が応答できる）（GCSアップロード → Job実行 → インデックス確認）

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

## クリーンアップ
- [ ] `terraform destroy`（依存順: cloud-run → ingestion → storage → firestore → observability → networking → secret-manager → artifact-registry → qdrant-cloud → elastic-cloud）
- [ ] Elastic Cloud コンソールからServerlessプロジェクト削除
- [ ] Qdrant Cloud コンソールからクラスタ削除
- [ ] Terraform state用GCSバケット削除
- [ ] GCPプロジェクト削除（任意）

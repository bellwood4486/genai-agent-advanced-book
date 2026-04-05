# ヘルプデスクエージェント GCPプロダクション構成 構築計画

## Context

chapter4の���ルプデスクAIエージェントを、`docs/production-architecture.md`の設計に基づいてGCPにデプロイする。目的はプロダクション構成要素の学習であり、実運用ではない（利用者は自分のみ）。コスト最小化を重視し、IaC (Terraform) で構築する。

**作業ディレクトリ**: `chapter4-prod/`（chapter4をベースにコピーし、クラウド対応の変更を加える）

**推定月額コスト**: ~$2-25（検索基盤はマネージドで数ドル、Cloud Run無料枠内、OpenAI API利用分のみ追加）

---

## ベストプラクティス準拠のポイント

| 技術 | ベストプラクティス | 計画への反映 |
|------|-------------------|-------------|
| **Terraform** | GCSバックエンド（バージョニング有効）、カスタムモジュール構成 | `infra/modules/`構成、GCS state backend |
| **Cloud Run** | v2 API (`google_cloud_run_v2_service`)、Direct VPC Egress | v2リソース、Direct VPC Egress |
| **FastAPI** | `async def` + `Depends()` + `@lru_cache`、lifespanでクライアント初期化 | 非同期エンドポイント、DI活用 |
| **LangGraph** | LangServeは非推奨 → カスタムFastAPIが推奨 | カスタムFastAPI採用 |
| **Dockerfile** | マルチステージビルド、`ghcr.io/astral-sh/uv`からコピー、`--frozen --no-dev` | 2段階ビルド |
| **Secret Manager** | Cloud Run環境変数参照（`value_source.secret_key_ref`） | env var参照方式 |
| **Artifact Registry** | Container Registry (gcr.io) は非推奨 | Artifact Registry使用 |
| **構造化ログ** | Cloud RunではJSON stdout出力で十分 | `python-json-logger` + `severity`フィールド |
| **トレース** | OpenTelemetry → Cloud Trace が標準 | OTel SDK使用 |
| **LB** | Global External ALB + Serverless NEG | Cloud Endpoints省略、LB直接構成 |
| **Elasticsearch** | Elastic Cloud ServerlessでKuromoji/ICU事前有効化済み | Serverless採用（GCE不要） |
| **Qdrant** | Qdrant Cloud Free Tierで学習用途は十分 | Free Tier採用（GCE不要） |
| **Elastic Terraform** | `elastic/ec`プロバイダで`elasticsearch_project`管理 | Serverlessプロジェクトをコード管理 |
| **Qdrant Terraform** | `qdrant/qdrant-cloud`プロバイダでクラスタ管理 | Free Tierクラスタをコード管理 |

---

## テスト戦略

各Incrementの成果を自動テストで検証する。手動curlによる確認は行わない。

### テストスタック

| ツール | 用途 |
|--------|------|
| `pytest` | テストランナー |
| `httpx` | FastAPI TestClient + 非同期HTTP（E2Eテスト） |
| `pytest-asyncio` | 非同期テスト対応 |
| `terraform validate` / `terraform plan` | IaC構文・計画検証 |

### テストディレクトリ構造

```
chapter4-prod/tests/
  conftest.py              # 共通fixture（Settings、モッククライアント等）
  unit/
    test_configs.py        # Settings読み込み、デフォルト値、env var上書き
    test_main.py           # FastAPI TestClientでエンドポイント検証（エージェントはモック）
    test_store.py          # Firestore store（モック）
    test_log_format.py     # 構造化ログのJSON形式検証
  integration/
    test_search_cloud.py   # Elastic Cloud / Qdrant Cloudへの接続・CRUD
    test_api_local.py      # ローカルDocker起動のAPIに対するテスト
    test_ingestion.py      # GCSアップロード → インデックス作成確認
    test_firestore.py      # Firestore読み書き
  e2e/
    test_cloud_run.py      # デプロイ済みCloud Run URLに対するスモークテスト
    test_eventarc.py       # GCSアップロード → 自動トリガー → 検索確認
    test_lb.py             # LB経由アクセス + Cloud Armorレート制限
```

### テストの分類と実行タイミング

| 分類 | 実行タイミング | 外部依存 | コスト |
|------|---------------|---------|--------|
| **Unit** | コード変更のたび（`uv run pytest tests/unit/`） | なし（全モック） | $0 |
| **Integration** | サービスプロビジョニング後（`uv run pytest tests/integration/`） | ES/Qdrant/GCS/Firestore | 最小限（従量課金の数リクエスト） |
| **E2E** | デプロイ後（`uv run pytest tests/e2e/`） | Cloud Run + 全バックエンド | OpenAI API呼び出し含む |

### Increment別テスト対応

| Increment | Unitテスト | Integrationテスト | E2Eテスト | Terraform検証 |
|-----------|-----------|-----------------|----------|--------------|
| 1: 設定リファクタ | `test_configs.py` | — | — | `terraform validate` |
| 2: FastAPI + Docker | `test_main.py` | `test_api_local.py` | — | — |
| 3: ES/Qdrant Cloud | — | `test_search_cloud.py` | — | `terraform plan/apply` |
| 4: GCP基盤 | — | — | — | `terraform plan/apply` |
| 5: Cloud Run MVP | — | — | `test_cloud_run.py` | `terraform plan/apply` |
| 6: Ingestion | — | `test_ingestion.py` | — | `terraform plan/apply` |
| 7: Eventarc | — | — | `test_eventarc.py` | `terraform plan/apply` |
| 8: Firestore | `test_store.py` | `test_firestore.py` | — | `terraform plan/apply` |
| 9: Observability | `test_log_format.py` | — | — | `terraform plan/apply` |
| 10: LB + Armor | — | — | `test_lb.py` | `terraform plan/apply` |
| 11: SSE | `test_main.py`に追加 | — | — | — |

---

## GitHub Actions

### ワークフローファイル構成

```
.github/workflows/
  chapter4-prod-ci.yml         # Lint + Unit tests（push / PR毎）
  chapter4-prod-deploy.yml     # Docker build & push（devへのmerge時）
  chapter4-prod-tf-plan.yml    # Terraform plan（infra/以下変更のPR時）
```

ファイル名を `chapter4-prod-` プレフィックスで統一することで、他のchapterのワークフローと混在しても識別できる。

### 各ワークフローの概要

| ファイル | トリガー | 内容 |
|--------|---------|------|
| `chapter4-prod-ci.yml` | push / PR（`chapter4-prod/**`変更時） | ruff lint + `uv run pytest tests/unit/` |
| `chapter4-prod-deploy.yml` | `dev`ブランチへのmerge（`chapter4-prod/**`変更時） | Dockerイメージビルド → Artifact Registryへpush |
| `chapter4-prod-tf-plan.yml` | PR（`chapter4-prod/infra/**`変更時） | `terraform plan`の結果をPRにコメント出力 |

### 自動化しないもの（手動運用）

| 操作 | 理由 |
|------|------|
| `terraform apply` | 学習目的のため手動適用で挙動を確認する |
| Integration / E2E テスト | 外部API（Elastic/Qdrant/OpenAI）への課金が発生するため、`workflow_dispatch`（手動トリガー）で必要時のみ実行 |

### GCP認証

初期はサービスアカウントキーをGitHub Secretsに登録して運用する。学習が進んだ段階でWorkload Identity Federation（キーレス認証）に移行することを検討する。

### GitHub Secrets / Variables の設定

Settings → Secrets and variables → Actions で以下を登録する:

**Secrets**（機密値 — マスクされて表示されない）:

| シークレット名 | 用途 |
|-------------|------|
| `GCP_SA_KEY` | GCPサービスアカウントキーのJSON（base64なしの生JSON） |

**Variables**（非機密値 — ログに表示される）:

| 変数名 | 値 | 用途 |
|--------|-----|------|
| `AR_REGION` | `asia-northeast1` | Artifact Registryのリージョン（Docker認証・イメージURL） |
| `GCP_PROJECT_ID` | `<your-project-id>` | GCPプロジェクトID（Terraform plan / Docker push共通） |

### Increment別の対応

| Increment | 追加・更新するワークフロー |
|-----------|------------------------|
| 1: 設定リファクタ | `chapter4-prod-ci.yml` 作成（lint + unit test） |
| 2: FastAPI + Docker | `chapter4-prod-deploy.yml` 作成（Artifact Registry push） |
| 4: GCP基盤 | `chapter4-prod-tf-plan.yml` 作成（terraform plan on PR） |

---

## 前提準備

### Step 0: GCPプロジェクト + Terraform + マネージドサービスアカウント準備

**やること**:
1. GCPプロジェクト作成（`gcloud projects create`）
2. 課金アカウントのリンク + 課金アラート設定（$10, $25, $50）
3. `gcloud auth application-default login`
4. Terraform インストール（`brew install terraform`）
5. Terraform state用GCSバケット作成（バージョニング有効、uniform bucket-level access）
6. Elastic Cloudアカウント作成 + APIキー取得（GCP Marketplace経由推奨）
7. Qdrant Cloudアカウント作成 + APIキー取得

**成果物**: `gcloud`、`terraform`が使える状態、Elastic Cloud / Qdrant Cloud のAPIキー取得済み

---

## Increment 1: プロジェクト雛形 + 設定リファクタ

**目的**: chapter4をコピーし、クラウドデプロイ可能な設定構造にする

**やること**:
- `chapter4-prod/` を作成し、chapter4の`src/`、`data/`、`pyproject.toml`、`uv.lock`等をコピー
- `src/configs.py`を拡張（デフォルト値でローカル互換を維持）:
  - `elasticsearch_url`（デフォルト: `http://localhost:9200`）
  - `qdrant_url`（デフォルト: `http://localhost:6333`）
  - `qdrant_api_key`（デフォルト: `None` — ローカルでは不要、Cloud時に設定）
- `src/tools/search_xyz_manual.py` — ハードコード`localhost:9200`をSettings経由に変更
- `src/tools/search_xyz_qa.py` — ハードコード`localhost:6333`をSettings経由に変更
- `chapter4-prod/CLAUDE.md` 作成（コマンド体系、Terraform規約、テスト実行方法、ディレクトリ構造）
- ルート `CLAUDE.md` に chapter4-prod セクション追加
- `chapter4-prod/.gitignore` 作成（Terraformパターン: `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars` + Python標準）
- `chapter4-prod/Makefile` 作成（`make test-unit`, `make test-integration`, `make test-e2e`, `make plan`, `make apply`, `make deploy` 等）
- Terraformディレクトリ構造を作成:
  ```
  chapter4-prod/infra/
    main.tf              # ルートモジュール（3プロバイダ統合）
    variables.tf
    outputs.tf
    providers.tf         # google + elastic + qdrant-cloud プロバイダ
    backend.tf           # GCS backend設定
    terraform.tfvars.example
    modules/
      elastic-cloud/     # Elastic Cloud Serverless project
      qdrant-cloud/      # Qdrant Cloud cluster (Free Tier)
      networking/        # VPC, サブネット（Cloud Run用）
      secret-manager/    # OpenAI APIキー等
      artifact-registry/ # Dockerリポジトリ
      cloud-run/         # v2 service + Direct VPC Egress
      storage/           # GCS（ドキュメントアップロード用）
      firestore/         # 会話履歴
      ingestion/         # Cloud Run Jobs + Eventarc
      observability/     # アラート
  ```

**変更ファイル**:
- `chapter4-prod/src/configs.py`
- `chapter4-prod/src/tools/search_xyz_manual.py`
- `chapter4-prod/src/tools/search_xyz_qa.py`
- `chapter4-prod/CLAUDE.md`（新規）
- `CLAUDE.md`（ルート）
- `chapter4-prod/.gitignore`（新規）
- `chapter4-prod/Makefile`（新規）

**検証**:
```bash
uv run pytest tests/unit/test_configs.py -v
terraform -chdir=infra validate
```
- `test_configs.py`: デフォルト値でSettings構築できること、env var上書きが反映されること、各toolがSettings経由のURLを使うことをモックで確認

---

## Increment 2: FastAPI + Dockerfile

**目的**: エージェントをHTTP APIとしてコンテナ化

**FastAPI設計** (ベストプラクティス準拠):
- `async def`エンドポイント（同期エージェントは`asyncio.to_thread()`でラップ）
- `Depends()` + `@lru_cache`でSettings/クライアントのDI
- `lifespan`イベントでElasticsearch/Qdrantクライアント初期化
- ヘルスチェックエンドポイント

**新規ファイル**:
- `chapter4-prod/src/main.py`:
  ```python
  # FastAPI app
  # GET /health — Cloud Run startup/liveness probe
  # POST /v1/chat  {"message": "..."} → {"answer": "..."}
  # lifespan: ES/Qdrantクライアント初期化
  # Depends()でSettings注入、@lru_cacheでシングルトン
  ```
- `chapter4-prod/Dockerfile`（マルチステージビルド）:
  ```dockerfile
  # Stage 1: 依存インストール
  FROM python:3.12-slim AS builder
  COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
  WORKDIR /app
  COPY pyproject.toml uv.lock ./
  RUN uv sync --frozen --no-dev --no-install-project

  # Stage 2: ランタイム
  FROM python:3.12-slim
  WORKDIR /app
  COPY --from=builder /app/.venv /app/.venv
  COPY src/ ./src/
  ENV PATH="/app/.venv/bin:$PATH"
  EXPOSE 8080
  CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
  ```
- `chapter4-prod/.dockerignore`

**検証**:
```bash
# Unitテスト（エージェントはモック）
uv run pytest tests/unit/test_main.py -v

# Integrationテスト（Dockerコンテナ起動 + 実際のES/Qdrantへの接続）
docker build -t helpdesk .
docker run -d -p 8080:8080 --env-file .env --name helpdesk-test helpdesk
uv run pytest tests/integration/test_api_local.py -v
docker rm -f helpdesk-test
```
- `test_main.py`: TestClientでヘルスチェック200、チャットリクエストの正常形式・バリデーションエラーをモック込みで確認
- `test_api_local.py`: Dockerコンテナ起動後に実ES/Qdrant接続ありでヘルスチェック + 実際の質問に回答が返ることを確認

---

## Increment 3: Elastic Cloud Serverless + Qdrant Cloud（Terraform）

**目的**: マネージド検索基盤をTerraformでプロビジョニング

**Terraformリソース**:
- `modules/elastic-cloud/`:
  - `elastic/ec`プロバイダ設定
  - `ec_elasticsearch_project`（Serverless Search project）
  - リージョン: GCPの東京 or 近いリージョン
- `modules/qdrant-cloud/`:
  - `qdrant/qdrant-cloud`プロバイダ設定
  - `qdrant-cloud_accounts_cluster`（Free Tier、GCPリージョン）
  - `qdrant-cloud_accounts_auth_key`（API key）

**コスト**: Qdrant $0 + Elastic ~$2-5/月（ほぼストレージのみ、VCUはゼロスケール）

**検証**:
```bash
terraform -chdir=infra plan
terraform -chdir=infra apply
uv run pytest tests/integration/test_search_cloud.py -v
```
- `test_search_cloud.py`: terraform outputsのエンドポイントURL + APIキーを使い、ES Serverlessにドキュメントをインデックスして検索できること、Qdrant Cloudにベクトルをupsertして検索できることを確認

---

## Increment 4: GCP基盤（Terraform）

**目的**: Cloud Run周辺のGCPリソースを作成

**Terraformリソース**:
- 必要なAPIの有効化: `run.googleapis.com`, `secretmanager.googleapis.com`, `artifactregistry.googleapis.com`
- `modules/networking/`: VPC + サブネット（Direct VPC Egress用 — 将来のFirestore等内部通信に備えて）
- `modules/secret-manager/`: `OPENAI_API_KEY`, `ELASTIC_API_KEY`, `QDRANT_API_KEY`
- `modules/artifact-registry/`: Dockerリポジトリ（cleanup policy: 30日で古いイメージ自動削除）
- Cloud Run用サービスアカウント:
  - `roles/secretmanager.secretAccessor`
  - `roles/artifactregistry.reader`

**検証**:
```bash
terraform -chdir=infra plan
terraform -chdir=infra apply
# Artifact Registryへのdocker push疎通確認
gcloud artifacts docker images list <region>-docker.pkg.dev/<project>/helpdesk
```

---

## Increment 5: Cloud Runデプロイ（MVP完成）

**目的**: エージェントがGCPで完全に動く — 最重要マイルストーン

**Terraformリソース** (`modules/cloud-run/`):
- `google_cloud_run_v2_service`:
  - Artifact Registryのイメージ
  - 環境変数: `ELASTICSEARCH_URL`, `QDRANT_URL`（Elastic Cloud / Qdrant CloudのエンドポイントURL）
  - Secret Manager参照: `OPENAI_API_KEY`, `ELASTIC_API_KEY`, `QDRANT_API_KEY`
  - `scaling { min_instance_count = 0, max_instance_count = 1 }`（スケールtoゼロ）
  - `timeout = "300s"`
  - `resources { limits = { cpu = "1", memory = "512Mi" } }`
- IAM: テスト用に`allUsers`で未認証アクセス許可（後で制限）

**手動ステップ**:
- アプリイメージをビルド＆Artifact Registryにpush

**検証**:
```bash
terraform -chdir=infra apply
# CLOUD_RUN_URL をterraform outputから取得してenvにセット
export CLOUD_RUN_URL=$(terraform -chdir=infra output -raw cloud_run_url)
uv run pytest tests/e2e/test_cloud_run.py -v
```
- `test_cloud_run.py`: `GET /health` が200を返すこと、`POST /v1/chat` に実際の質問を送り非空の回答が返ること（LLM呼び出しを含む実E2E）

**ここがMVP — エンドツーエンドでクラウド上で動作する**

**注**: マネージドES/Qdrantはパブリックエンドポイントなので、Cloud Runから直接HTTPS接続。VPC Egress不要（ただし将来のFirestore等に備えてVPCは作成済み）。

---

## Increment 6: GCS + Cloud Run Jobs（インデックス作成パイプライン）

**目的**: ドキュメントインジェスションパイプラインの構築

**Terraformリソース** (`modules/storage/`, `modules/ingestion/`):
- `google_storage_bucket` — ドキュメントアップロード先
- `google_cloud_run_v2_job` — インデックス作成ジョブ（冪等: document IDベースでupsert）

**アプリ変更**:
- `google-cloud-storage`を依存に追加
- `src/scripts/create_index.py`をリファクタ: GCSからファイル読み取り対応
- Elastic Cloud / Qdrant Cloud向けの接続設定

**検証**:
```bash
terraform -chdir=infra apply
uv run pytest tests/integration/test_ingestion.py -v
```
- `test_ingestion.py`: テスト用PDFをGCSにアップロード → Jobを手動実行 → ES/QdrantのドキュメントIDが存在することを確認 → `test_cloud_run.py`でそのドキュメントに関する質問に回答できることを確認

---

## Increment 7: Eventarc自動トリガー

**目的**: ファイルアップロードで自動インデックス作成

**Terraformリソース** (`modules/ingestion/`に追加):
- `google_eventarc_trigger`:
  - イベント: `google.cloud.storage.object.v1.finalized`
  - ターゲット: Cloud Run Job
- Eventarc用IAM

**アプリ変更**:
- インデックス作成ジョブがイベントペイロード（ファイルパス）を受け取り、そのファイルのみ処理
- 冪等性確保（同じファイルの再アップロードでも安全）

**検証**:
```bash
terraform -chdir=infra apply
uv run pytest tests/e2e/test_eventarc.py -v
```
- `test_eventarc.py`: GCSにファイルをアップロード → Cloud Run Jobsの実行履歴をポーリングして完了を確認 → ES/Qdrantにドキュメントが存在することを確認

---

## Increment 8: Firestore会話履歴

**目的**: 会話の永続化（Memorystore Redisはコスト高のためスキップ）

**Terraformリソース** (`modules/firestore/`):
- `google_firestore_database`（Native mode、無料枠内）
- Cloud Runサービスアカウントに`roles/datastore.user`

**アプリ変更**:
- `google-cloud-firestore`を依存に追加
- `src/store.py`作成: `save_conversation()`, `get_conversations()`
- FastAPIエンドポイント追加: `GET /v1/conversations`, `GET /v1/conversations/{id}`
- `/v1/chat`の完了後に非同期で会話保存

**検証**:
```bash
uv run pytest tests/unit/test_store.py -v
uv run pytest tests/integration/test_firestore.py -v
```
- `test_store.py`: モックFirestoreクライアントで`save_conversation()`/`get_conversations()`の正常動作を確認
- `test_firestore.py`: 実Firestoreに接続し、チャットAPI経由で会話が保存されること、`GET /v1/conversations`で取得できることをhttpxで確認

---

## Increment 9: Observability（構造化ログ + トレース + アラート）

**目的**: 可観測性の構築を学ぶ

**Terraformリソース** (`modules/observability/`):
- `google_monitoring_alert_policy`（Cloud Runエラー率アラート）
- `google_monitoring_notification_channel`（メール通知）

**アプリ変更**:
- 構造化JSONログ（`python-json-logger`使用、`severity`フィールド付き）
- `X-Cloud-Trace-Context`ヘッダーからトレースID抽出、ログに`logging.googleapis.com/trace`付与
- OpenTelemetry導入:
  - `opentelemetry-sdk` + `opentelemetry-exporter-gcp-trace` + `opentelemetry-instrumentation-fastapi`
  - エージェント各ステップにスパン追加
- リクエストIDミドルウェア

**検証**:
```bash
uv run pytest tests/unit/test_log_format.py -v
# E2Eリクエスト後にCloud Loggingをクエリして確認
export CLOUD_RUN_URL=$(terraform -chdir=infra output -raw cloud_run_url)
uv run pytest tests/e2e/test_cloud_run.py -v  # リクエスト生成
gcloud logging read 'resource.type="cloud_run_revision" severity>=INFO jsonPayload.request_id!=""' --limit=5
```
- `test_log_format.py`: ログ出力が`severity`, `message`, `request_id`フィールドを持つ正しいJSON形式であることをユニットテストで確認

---

## Increment 10（オプション）: Global LB + Cloud Armor

**目的**: APIゲートウェイとWAFを学ぶ（+~$18/月）

**Terraformリソース**:
- Serverless NEG → Backend Service（timeout: 300s）→ URL Map → HTTPS Proxy
- Cloud Armorセキュリティポリシー（Standard tier無料）:
  - レート制限ルール（例: 10 req/min per IP）
  - OWASP Top 10 preconfigured rules
- Cloud Run ingress → `internal-and-cloud-load-balancing`に変更

**検証**:
```bash
terraform -chdir=infra apply
export LB_URL=$(terraform -chdir=infra output -raw lb_url)
uv run pytest tests/e2e/test_lb.py -v
```
- `test_lb.py`: LB URL経由でヘルスチェックとチャットが正常動作すること、11回連続リクエストで429が返ることを確認

---

## Increment 11（オプション）: SSEストリーミング

**目的**: リアルタイムなエージェント進捗表示

**アプリ変更**:
- `POST /v1/chat/stream` — `StreamingResponse` + `media_type="text/event-stream"`
- LangGraphの`graph.astream()`で各ステップをSSEイベントとして送出

**検証**:
```bash
uv run pytest tests/unit/test_main.py::test_chat_stream -v
uv run pytest tests/e2e/test_cloud_run.py::test_chat_stream -v
```
- SSEレスポンスのContent-Typeが`text/event-stream`であること、`data:`行が複数返ることをhttpxのストリームAPIで確認

---

## クリーンアップ手順

学習完了後、課金が継続しないようにリソースを削除する。依存関係の逆順でdestroyすること。

### Terraform管理リソースの削除

```bash
# 依存関係を考慮した destroy 順序（モジュール指定）
terraform -chdir=infra destroy -target=module.cloud-run
terraform -chdir=infra destroy -target=module.ingestion    # Eventarc + Cloud Run Jobs
terraform -chdir=infra destroy -target=module.storage      # GCSバケット（空にしてから）
terraform -chdir=infra destroy -target=module.firestore
terraform -chdir=infra destroy -target=module.observability
terraform -chdir=infra destroy -target=module.networking
terraform -chdir=infra destroy -target=module.secret-manager
terraform -chdir=infra destroy -target=module.artifact-registry
terraform -chdir=infra destroy -target=module.qdrant-cloud
terraform -chdir=infra destroy -target=module.elastic-cloud
# 最後に全体確認
terraform -chdir=infra destroy
```

### マネージドサービスの解約

| サービス | 操作 |
|--------|------|
| Elastic Cloud | コンソールからServerlessプロジェクト削除 → 不要ならアカウント解約 |
| Qdrant Cloud | コンソールからクラスタ削除（Free Tierなので課金なし） |

### GCP側の手動削除

```bash
# Terraform stateバケット（バージョニングされたオブジェクトも含め削除）
gsutil -m rm -r gs://<your-tf-state-bucket>
gcloud storage buckets delete gs://<your-tf-state-bucket>

# GCPプロジェクトごと削除（最終手段 — 全リソース一括削除）
gcloud projects delete <project-id>
```

---

## アーキテクチャ概要（最終形）

```
Client → [Cloud LB + Cloud Armor] → Cloud Run (FastAPI)
                                        ├── Elastic Cloud Serverless (キーワード検索)
                                        ├── Qdrant Cloud (ベクトル検索)
                                        ├── OpenAI API (LLM + Embedding)
                                        ├── Firestore (会話履歴)
                                        └── Cloud Monitoring / Trace (可観測性)

GCS → Eventarc → Cloud Run Jobs (インデックス作成)
                    ├── Elastic Cloud Serverless
                    └── Qdrant Cloud
```

## 進め方

各Incrementを1つずつ順番に実装・検証する。**Increment 5（MVP）が最重要マイルストーン**。

**GCE完全不要**: 検索基盤をマネージドサービスにしたことで、GCEインスタンスの管理が不要に。VPC/ファイアウォール設定もシンプルになり、Terraform管理するプロバイダは3つ（Google + Elastic + Qdrant）だが、各サービスの責務が明確に分離。

---

## 参考リンク

- [Elastic Cloud ServerlessでKuromojiが使えることを確認](https://qiita.com/nobuhikosekiya/items/3c1c546f6f12705a34cc)
- [Elasticsearch Serverless pricing: VCUs and ECUs explained](https://www.elastic.co/search-labs/blog/elasticsearch-serverless-pricing-vcus-ecus)
- [Qdrant Cloud Pricing](https://qdrant.tech/pricing/)
- [Qdrant Cloud Terraform Provider](https://registry.terraform.io/providers/qdrant/qdrant-cloud/latest/docs)
- [Elastic Cloud Terraform Provider](https://registry.terraform.io/providers/elastic/ec/latest/docs)
- [Elastic Cloud Serverless on GCP Marketplace](https://www.apmdigest.com/elastic-cloud-serverless-available-google-cloud-marketplace)

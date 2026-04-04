# chapter4-prod CLAUDE.md

GCPプロダクション構成のヘルプデスクAIエージェント。chapter4をベースにCloud Run + Elastic Cloud + Qdrant Cloud + Firestoreへデプロイする。

## ディレクトリ構造

```
chapter4-prod/
  src/
    agent.py            # LangGraphエージェント
    configs.py          # Pydantic Settings（ES/Qdrant URL含む）
    custom_logger.py
    models.py
    prompts.py
    tools/
      search_xyz_manual.py   # Elasticsearchキーワード検索
      search_xyz_qa.py       # Qdrantベクトル検索
    scripts/
      create_index.py        # インデックス作成（ローカル + GCS対応）
      delete_index.py        # インデックス削除
  data/                 # PDFs + CSVs（インデックス作成用）
  tests/
    conftest.py
    unit/               # モックのみ、外部依存なし
    integration/        # ES/Qdrant/GCS/Firestore接続あり
    e2e/                # Cloud Run URLに対するスモークテスト
  infra/
    providers.tf        # google + elastic/ec + qdrant-cloud
    backend.tf          # GCS state backend
    variables.tf
    main.tf
    outputs.tf
    terraform.tfvars.example
    modules/
      elastic-cloud/    # Increment 3
      qdrant-cloud/     # Increment 3
      networking/       # Increment 4
      secret-manager/   # Increment 4
      artifact-registry/ # Increment 4
      cloud-run/        # Increment 5
      storage/          # Increment 6
      ingestion/        # Increment 6, 7
      firestore/        # Increment 8
      observability/    # Increment 9
  docs/
    deployment-plan.md  # 実装計画（11 Increments）
    progress.md         # 進捗チェックリスト
```

## 環境変数

`.env.sample` をコピーして `.env` を作成:

```
OPENAI_API_KEY=...
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-2024-08-06

# クラウド構成時のみ設定（デフォルトはlocalhost）
ELASTICSEARCH_URL=https://...
QDRANT_URL=https://...
QDRANT_API_KEY=...
```

## コマンド

```bash
uv sync                  # 依存インストール
make lint                # Ruff lint
make format              # Ruff format
make test-unit           # Unit tests（外部依存なし）
make test-integration    # Integration tests（ES/Qdrant/GCS/Firestore）
make test-e2e            # E2E tests（Cloud Run URL）
make start-engine        # ローカルES + Qdrant起動（Docker）
make stop-engine         # ローカルES + Qdrant停止
make create-index        # インデックス作成
make delete-index        # インデックス削除
make validate            # terraform init -backend=false + validate
make plan                # terraform plan
make apply               # terraform apply（手動）
```

## Terraform規約

- ステートはGCS backend（`backend.tf`）
- 変数の機密値は `terraform.tfvars`（gitignore済み）に記載、`terraform.tfvars.example` に例を置く
- モジュールは `infra/modules/` 配下に機能単位で分割
- `terraform apply` は自動化せず手動実行（学習目的）
- Increment 1では `terraform init -backend=false` でバックエンドなしでvalidate

## 開発フロー

- 実装は **Increment単位** で進める（`docs/deployment-plan.md` の11 Incrementsに従う）
- 1つのIncrementの実装が完了したら、**`dev` ブランチへのPR**を作成する
- 人間がPRをレビュー・マージしてから次のIncrementへ進む
- すでに実装済みのIncrementはこのルールの対象外
- Python・Terraform固有の技術要素には、**理解の助けとなるコメント**を積極的に書く（言語仕様、フレームワークの仕組み、設定の意図など）

## テスト方針

| 分類 | 実行タイミング | コマンド |
|------|--------------|---------|
| Unit | コード変更のたびに | `make test-unit` |
| Integration | サービスプロビジョニング後 | `make test-integration` |
| E2E | Cloud Runデプロイ後 | `make test-e2e` |

詳細は `docs/deployment-plan.md` のテスト戦略セクションを参照。

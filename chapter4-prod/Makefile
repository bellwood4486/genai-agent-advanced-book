.PHONY: lint
lint:
	@uv run ruff check .

.PHONY: format
format:
	@uv run ruff format .

.PHONY: test-unit
test-unit:
	@uv run pytest tests/unit/ -v

.PHONY: test-integration
test-integration:
	@# $(shell ...) は Makefile のパース時に評価され、コマンドにインライン展開される。
	@# terraform output から接続情報を取得して環境変数としてテストプロセスに渡す。
	@ELASTICSEARCH_URL=$(shell terraform -chdir=infra output -raw elasticsearch_endpoint 2>/dev/null) \
	 ELASTICSEARCH_USERNAME=$(shell terraform -chdir=infra output -json elasticsearch_credentials 2>/dev/null | jq -r .username) \
	 ELASTICSEARCH_PASSWORD=$(shell terraform -chdir=infra output -json elasticsearch_credentials 2>/dev/null | jq -r .password) \
	 QDRANT_URL=$(shell terraform -chdir=infra output -raw qdrant_endpoint 2>/dev/null) \
	 QDRANT_API_KEY=$(shell terraform -chdir=infra output -raw qdrant_api_key 2>/dev/null) \
	 GCS_BUCKET_NAME=$(shell terraform -chdir=infra output -raw gcs_bucket_name 2>/dev/null) \
	 uv run pytest tests/integration/ -v

.PHONY: test-e2e
test-e2e:
	@uv run pytest tests/e2e/ -v

.PHONY: start-engine
start-engine:
	@docker compose up -d

.PHONY: stop-engine
stop-engine:
	@docker compose down

.PHONY: create-index
create-index:
	@uv run python -m src.scripts.create_index

.PHONY: delete-index
delete-index:
	@uv run python -m src.scripts.delete_index

.PHONY: validate
validate:
	@terraform -chdir=infra init -backend=false -reconfigure
	@terraform -chdir=infra validate

.PHONY: plan
plan:
	@terraform -chdir=infra plan

.PHONY: apply
apply:
	@terraform -chdir=infra apply

.PHONY: upload-docs
upload-docs:
	@# data/ 内のドキュメントを GCS バケットにアップロードする（Increment 6）。
	@# バケット名は terraform output から取得する。
	@gcloud storage cp data/*.pdf data/*.csv \
		gs://$(shell terraform -chdir=infra output -raw gcs_bucket_name 2>/dev/null)/

.PHONY: run-ingestion
run-ingestion:
	@# Cloud Run Job を手動実行し、GCS のドキュメントから ES/Qdrant インデックスを作成する（Increment 6）。
	@# --wait: ジョブの完了（または失敗）を待ってからコマンドを返す（デフォルトは非同期）。
	@# --region: ジョブがデプロイされたリージョンを指定する。
	@gcloud run jobs execute \
		$(shell terraform -chdir=infra output -raw ingestion_job_name 2>/dev/null) \
		--region asia-northeast1 \
		--wait

.PHONY: deploy
deploy:
	@echo "Build and push Docker image to Artifact Registry"
	@echo "Set REGION, PROJECT_ID, and IMAGE_TAG before running"

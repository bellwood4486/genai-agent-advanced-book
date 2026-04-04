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
	@uv run pytest tests/integration/ -v

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

.PHONY: deploy
deploy:
	@echo "Build and push Docker image to Artifact Registry"
	@echo "Set REGION, PROJECT_ID, and IMAGE_TAG before running"

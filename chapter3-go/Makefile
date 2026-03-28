.PHONY: run-basic run-json-mode run-structured run-function-calling \
        run-tavily run-duckduckgo run-text-to-sql run-workflow \
        setup-db teardown-db

run-basic:
	go run ./cmd/s31_basic/

run-json-mode:
	go run ./cmd/s31_json_mode/

run-structured:
	go run ./cmd/s31_structured/

run-function-calling:
	go run ./cmd/s32_function_calling/

run-tavily:
	go run ./cmd/s33_tavily/

run-duckduckgo:
	go run ./cmd/s33_duckduckgo/

run-text-to-sql:
	go run ./cmd/s33_text_to_sql/

run-workflow:
	go run ./cmd/s36_workflow/

setup-db:
	docker-compose up -d

teardown-db:
	docker-compose down -v

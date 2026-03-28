# Chapter 3 (Go版)

第3章のサンプルコードを Go で実装したものです。

## 前提条件

- Go 1.24+
- Docker + Docker Compose
- OpenAI API キー
- Tavily API キー

## セットアップ

```bash
# 依存パッケージのインストール
go mod download

# .env ファイルの作成
cp .env.example .env
# .env を編集して API キーを設定

# PostgreSQL の起動 (Text-to-SQL に必要)
docker-compose up -d
```

## 実行方法

各サンプルを個別に実行できます。

```bash
# 3.1.2 基本的なチャット補完 + トークン使用量
go run ./cmd/s31_basic/

# 3.1.5 JSON モード
go run ./cmd/s31_json_mode/

# 3.1.5 構造化出力 (Recipe)
go run ./cmd/s31_structured/

# 3.2 Function Calling
go run ./cmd/s32_function_calling/

# 3.3.1 Tavily ウェブ検索
go run ./cmd/s33_tavily/

# 3.3.1 DuckDuckGo 検索 + Web フェッチ
go run ./cmd/s33_duckduckgo/

# 3.3.2 Text-to-SQL (要: PostgreSQL 起動)
go run ./cmd/s33_text_to_sql/

# 3.6 エージェントワークフロー
go run ./cmd/s36_workflow/
```

Makefile を使う場合:

```bash
make run-basic
make run-json-mode
make run-structured
make run-function-calling
make run-tavily
make run-duckduckgo
make run-text-to-sql   # 要: PostgreSQL 起動
make run-workflow
```

## 使用ライブラリ

| ライブラリ | 用途 |
|-----------|------|
| `github.com/openai/openai-go` | OpenAI API クライアント |
| `github.com/jackc/pgx/v5` | PostgreSQL ドライバー |
| `github.com/joho/godotenv` | .env ファイル読み込み |

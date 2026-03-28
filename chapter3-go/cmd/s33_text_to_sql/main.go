// 3.3.2 Text-to-SQL (プライベートデータ検索)
// PostgreSQL のスキーマを取得し、自然言語クエリを SQL に変換して実行する。
package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
	"github.com/jackc/pgx/v5"
	"github.com/openai/openai-go"
)

// getTableSchema は PostgreSQL から指定テーブルのカラム情報を取得する。
func getTableSchema(ctx context.Context, conn *pgx.Conn, tableName string) (string, error) {
	rows, err := conn.Query(ctx, `
		SELECT column_name, data_type, is_nullable
		FROM information_schema.columns
		WHERE table_name = $1
		ORDER BY ordinal_position
	`, tableName)
	if err != nil {
		return "", err
	}
	defer rows.Close()

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("テーブル: %s\n", tableName))
	sb.WriteString("カラム:\n")
	for rows.Next() {
		var colName, dataType, isNullable string
		if err := rows.Scan(&colName, &dataType, &isNullable); err != nil {
			return "", err
		}
		sb.WriteString(fmt.Sprintf("  - %s (%s, nullable: %s)\n", colName, dataType, isNullable))
	}
	return sb.String(), rows.Err()
}

// generateSQL は LLM にスキーマと自然言語クエリを渡して SQL を生成する。
func generateSQL(ctx context.Context, client openai.Client, schema, question string) (string, error) {
	prompt := fmt.Sprintf(`以下の PostgreSQL テーブルスキーマを参照して、質問に答えるための SQL クエリを生成してください。

%s

質問: %s

SQL クエリのみを返してください。説明は不要です。`, schema, question)

	resp, err := client.Chat.Completions.New(ctx, openai.ChatCompletionNewParams{
		Model: openai.ChatModelGPT4oMini,
		Messages: []openai.ChatCompletionMessageParamUnion{
			openai.UserMessage(prompt),
		},
	})
	if err != nil {
		return "", err
	}

	// コードブロック記法を除去
	sql := strings.TrimSpace(resp.Choices[0].Message.Content)
	sql = strings.TrimPrefix(sql, "```sql")
	sql = strings.TrimPrefix(sql, "```")
	sql = strings.TrimSuffix(sql, "```")
	return strings.TrimSpace(sql), nil
}

func main() {
	envutil.Load()

	pgUser := envutil.MustGetenv("PGUSER")
	pgPassword := envutil.MustGetenv("PGPASSWORD")
	pgHost := envutil.MustGetenv("PGHOST")
	pgPort := envutil.MustGetenv("PGPORT")
	pgDatabase := envutil.MustGetenv("PGDATABASE")

	connStr := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", pgUser, pgPassword, pgHost, pgPort, pgDatabase)

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, connStr)
	if err != nil {
		panic(fmt.Sprintf("PostgreSQL 接続エラー: %v", err))
	}
	defer conn.Close(ctx)

	// テーブルスキーマを取得
	schema, err := getTableSchema(ctx, conn, "employees")
	if err != nil {
		panic(err)
	}
	fmt.Println("=== テーブルスキーマ ===")
	fmt.Println(schema)

	// 自然言語クエリを SQL に変換
	question := "employeeテーブルの情報は何件ありますか？"
	fmt.Printf("=== 質問 ===\n%s\n\n", question)

	aiClient := openai.NewClient()
	sql, err := generateSQL(ctx, aiClient, schema, question)
	if err != nil {
		panic(err)
	}
	fmt.Printf("=== 生成された SQL ===\n%s\n\n", sql)

	// SQL を実行
	rows, err := conn.Query(ctx, sql)
	if err != nil {
		panic(fmt.Sprintf("SQL 実行エラー: %v", err))
	}
	defer rows.Close()

	fmt.Println("=== クエリ結果 ===")
	fieldDescs := rows.FieldDescriptions()
	headers := make([]string, len(fieldDescs))
	for i, fd := range fieldDescs {
		headers[i] = string(fd.Name)
	}
	fmt.Println(strings.Join(headers, " | "))

	for rows.Next() {
		values, err := rows.Values()
		if err != nil {
			panic(err)
		}
		strs := make([]string, len(values))
		for i, v := range values {
			strs[i] = fmt.Sprintf("%v", v)
		}
		fmt.Println(strings.Join(strs, " | "))
	}
	if err := rows.Err(); err != nil {
		panic(err)
	}
}

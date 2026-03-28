// 3.1.2 基本的なチャット補完
// OpenAI API を使ってチャット補完を行い、トークン使用量を表示する。
package main

import (
	"context"
	"fmt"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
	"github.com/openai/openai-go"
)

func main() {
	envutil.Load()

	client := openai.NewClient() // OPENAI_API_KEY を環境変数から読み込む

	resp, err := client.Chat.Completions.New(context.Background(), openai.ChatCompletionNewParams{
		Model: openai.ChatModelGPT4o,
		Messages: []openai.ChatCompletionMessageParamUnion{
			openai.UserMessage("今日の天気は何ですか？"),
		},
	})
	if err != nil {
		panic(err)
	}

	fmt.Println("=== レスポンス ===")
	fmt.Println(resp.Choices[0].Message.Content)

	fmt.Println("\n=== トークン使用量 ===")
	fmt.Printf("プロンプトトークン数:    %d\n", resp.Usage.PromptTokens)
	fmt.Printf("補完トークン数:          %d\n", resp.Usage.CompletionTokens)
	fmt.Printf("合計トークン数:          %d\n", resp.Usage.TotalTokens)
}

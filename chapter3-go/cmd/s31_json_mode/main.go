// 3.1.5 JSON モード
// response_format に json_object を指定して JSON 形式のレスポンスを取得する。
package main

import (
	"context"
	"fmt"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
	"github.com/openai/openai-go"
	"github.com/openai/openai-go/shared"
)

func main() {
	envutil.Load()

	client := openai.NewClient()

	resp, err := client.Chat.Completions.New(context.Background(), openai.ChatCompletionNewParams{
		Model: openai.ChatModelGPT4o,
		Messages: []openai.ChatCompletionMessageParamUnion{
			openai.SystemMessage("必ず JSON 形式で回答してください。"),
			openai.AssistantMessage(`{"winner": String}`),
			openai.UserMessage("2020年のワールドシリーズで優勝したのはどこですか？"),
		},
		ResponseFormat: openai.ChatCompletionNewParamsResponseFormatUnion{
			OfJSONObject: func() *shared.ResponseFormatJSONObjectParam {
				p := shared.NewResponseFormatJSONObjectParam()
				return &p
			}(),
		},
	})
	if err != nil {
		panic(err)
	}

	fmt.Println("=== JSON レスポンス ===")
	fmt.Println(resp.Choices[0].Message.Content)
}

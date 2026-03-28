// 3.2 Function Calling
// ツール定義を API に渡し、モデルが関数呼び出しを要求したら実行して結果を返す 2ステップループ。
package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
	"github.com/openai/openai-go"
	"github.com/openai/openai-go/shared"
)

// getWeather は指定された場所の天気を返すダミー関数。
func getWeather(location string) string {
	weather := map[string]string{
		"Tokyo": "晴れ、気温25度",
		"Osaka": "曇り、気温23度",
		"Kyoto": "雨、気温20度",
	}
	if w, ok := weather[location]; ok {
		return w
	}
	return "天気情報が見つかりません"
}

func main() {
	envutil.Load()

	client := openai.NewClient()

	tools := []openai.ChatCompletionToolParam{
		{
			Function: shared.FunctionDefinitionParam{
				Name:        "get_weather",
				Description: openai.String("指定された場所の現在の天気を取得する"),
				Parameters: shared.FunctionParameters{
					"type": "object",
					"properties": map[string]any{
						"location": map[string]any{
							"type":        "string",
							"description": "天気を知りたい場所（例: Tokyo）",
						},
					},
					"required": []string{"location"},
				},
			},
		},
	}

	messages := []openai.ChatCompletionMessageParamUnion{
		openai.UserMessage("東京の天気を教えてください。"),
	}

	// ステップ1: ツールを渡して API を呼び出す
	fmt.Println("=== ステップ1: モデルへの初回リクエスト ===")
	resp, err := client.Chat.Completions.New(context.Background(), openai.ChatCompletionNewParams{
		Model:    openai.ChatModelGPT4o,
		Messages: messages,
		Tools:    tools,
	})
	if err != nil {
		panic(err)
	}

	assistantMsg := resp.Choices[0].Message

	// モデルがツール呼び出しを要求したか確認
	if len(assistantMsg.ToolCalls) == 0 {
		fmt.Println("モデルはツールを呼び出しませんでした。")
		fmt.Println(assistantMsg.Content)
		return
	}

	toolCall := assistantMsg.ToolCalls[0]
	fmt.Printf("モデルが要求したツール: %s\n", toolCall.Function.Name)
	fmt.Printf("引数: %s\n", toolCall.Function.Arguments)

	// ステップ2: ツールを実行して結果を返す
	var args map[string]string
	if err := json.Unmarshal([]byte(toolCall.Function.Arguments), &args); err != nil {
		panic(err)
	}

	toolResult := getWeather(args["location"])
	fmt.Printf("\n=== ツール実行結果 ===\n%s\n", toolResult)

	// アシスタントのツール呼び出しメッセージを追加
	messages = append(messages, openai.ChatCompletionMessageParamUnion{
		OfAssistant: &openai.ChatCompletionAssistantMessageParam{
			ToolCalls: []openai.ChatCompletionMessageToolCallParam{
				{
					ID: toolCall.ID,
					Function: openai.ChatCompletionMessageToolCallFunctionParam{
						Name:      toolCall.Function.Name,
						Arguments: toolCall.Function.Arguments,
					},
				},
			},
		},
	})
	// ツール結果メッセージを追加
	messages = append(messages, openai.ToolMessage(toolResult, toolCall.ID))

	// 最終回答を取得
	fmt.Println("\n=== ステップ2: 最終回答 ===")
	finalResp, err := client.Chat.Completions.New(context.Background(), openai.ChatCompletionNewParams{
		Model:    openai.ChatModelGPT4o,
		Messages: messages,
	})
	if err != nil {
		panic(err)
	}

	fmt.Println(finalResp.Choices[0].Message.Content)
}

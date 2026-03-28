// 3.1.5 構造化出力 (Structured Outputs)
// JSON Schema を使って型付きのレスポンスを取得する。
package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
	"github.com/openai/openai-go"
	"github.com/openai/openai-go/shared"
)

// Recipe はレシピの構造を定義する。
type Recipe struct {
	Name        string   `json:"name"`
	Servings    int      `json:"servings"`
	Ingredients []string `json:"ingredients"`
	Steps       []string `json:"steps"`
}

// recipeSchema は Recipe の JSON Schema 定義。
var recipeSchema = map[string]any{
	"type": "object",
	"properties": map[string]any{
		"name":        map[string]any{"type": "string"},
		"servings":    map[string]any{"type": "integer"},
		"ingredients": map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
		"steps":       map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
	},
	"required":             []string{"name", "servings", "ingredients", "steps"},
	"additionalProperties": false,
}

func main() {
	envutil.Load()

	client := openai.NewClient()

	resp, err := client.Chat.Completions.New(context.Background(), openai.ChatCompletionNewParams{
		Model: openai.ChatModelGPT4o,
		Messages: []openai.ChatCompletionMessageParamUnion{
			openai.UserMessage("タコライスのレシピを教えてください。"),
		},
		ResponseFormat: openai.ChatCompletionNewParamsResponseFormatUnion{
			OfJSONSchema: &shared.ResponseFormatJSONSchemaParam{
				JSONSchema: shared.ResponseFormatJSONSchemaJSONSchemaParam{
					Name:   "Recipe",
					Schema: recipeSchema,
					Strict: openai.Bool(true),
				},
			},
		},
	})
	if err != nil {
		panic(err)
	}

	var recipe Recipe
	if err := json.Unmarshal([]byte(resp.Choices[0].Message.Content), &recipe); err != nil {
		panic(err)
	}

	fmt.Println("=== レシピ ===")
	fmt.Printf("料理名:     %s\n", recipe.Name)
	fmt.Printf("人数:       %d人分\n", recipe.Servings)
	fmt.Println("\n材料:")
	for _, ing := range recipe.Ingredients {
		fmt.Printf("  - %s\n", ing)
	}
	fmt.Println("\n手順:")
	for i, step := range recipe.Steps {
		fmt.Printf("  %d. %s\n", i+1, step)
	}
}

// 3.3.1 Tavily ウェブ検索ツール
// Tavily API を使ってウェブ検索を実行し、結果を表示する。
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
)

type tavilyRequest struct {
	APIKey     string `json:"api_key"`
	Query      string `json:"query"`
	MaxResults int    `json:"max_results"`
}

type tavilyResult struct {
	Title   string `json:"title"`
	URL     string `json:"url"`
	Content string `json:"content"`
}

type tavilyResponse struct {
	Results []tavilyResult `json:"results"`
}

func search(apiKey, query string, maxResults int) ([]tavilyResult, error) {
	body, err := json.Marshal(tavilyRequest{
		APIKey:     apiKey,
		Query:      query,
		MaxResults: maxResults,
	})
	if err != nil {
		return nil, err
	}

	resp, err := http.Post("https://api.tavily.com/search", "application/json", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var result tavilyResponse
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, fmt.Errorf("レスポンス解析エラー: %w\nボディ: %s", err, data)
	}
	return result.Results, nil
}

func main() {
	envutil.Load()
	apiKey := envutil.MustGetenv("TAVILY_API_KEY")

	results, err := search(apiKey, "AIエージェント 実践本", 3)
	if err != nil {
		panic(err)
	}

	fmt.Println("=== Tavily 検索結果 ===")
	for i, r := range results {
		fmt.Printf("\n[%d] %s\n", i+1, r.Title)
		fmt.Printf("URL: %s\n", r.URL)
		fmt.Printf("概要: %s\n", r.Content)
	}
}

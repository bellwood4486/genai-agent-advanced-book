// 3.3.1 DuckDuckGo 検索ツール + Web フェッチ
// DuckDuckGo の Lite エンドポイントで検索し、最初のURLの内容を取得する。
package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
)

type searchResult struct {
	Title   string
	Snippet string
	URL     string
}

// duckduckgoSearch は DuckDuckGo Lite に POST 検索し、上位 maxResults 件を返す。
func duckduckgoSearch(query string, maxResults int) ([]searchResult, error) {
	form := url.Values{}
	form.Set("q", query)
	form.Set("kl", "jp-jp")

	req, err := http.NewRequest("POST", "https://lite.duckduckgo.com/lite/", strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "Mozilla/5.0 (compatible; Go/1.24)")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return parseResults(string(body), maxResults), nil
}

// parseResults は DuckDuckGo Lite の HTML からタイトル・スニペット・URL を抽出する。
// 実際の HTML: <a rel="nofollow" href="URL" class='result-link'>タイトル</a>
func parseResults(html string, maxResults int) []searchResult {
	// 広告以外の通常検索結果のみを対象とする (duckduckgo.com/y.js は広告)
	// href は二重引用符, class は単引用符を使う: href="URL" class='result-link'
	linkRe := regexp.MustCompile(`<a[^>]+href="([^"]+)"[^>]+class='result-link'>([^<]+)</a>`)
	snippetRe := regexp.MustCompile(`<td[^>]+class='result-snippet'[^>]*>([\s\S]*?)</td>`)
	tagRe := regexp.MustCompile(`<[^>]+>`)

	links := linkRe.FindAllStringSubmatch(html, -1)
	snippets := snippetRe.FindAllStringSubmatch(html, -1)

	var results []searchResult
	snippetIdx := 0
	for _, link := range links {
		if len(results) >= maxResults {
			break
		}
		rawURL := link[1]
		// 広告リンク (y.js) を除外
		if strings.Contains(rawURL, "duckduckgo.com/y.js") {
			snippetIdx++
			continue
		}
		title := strings.TrimSpace(link[2])
		snippet := ""
		if snippetIdx < len(snippets) {
			snippet = strings.TrimSpace(tagRe.ReplaceAllString(snippets[snippetIdx][1], ""))
		}
		results = append(results, searchResult{
			Title:   title,
			Snippet: snippet,
			URL:     rawURL,
		})
		snippetIdx++
	}
	return results
}

func main() {
	envutil.Load()

	fmt.Println("=== DuckDuckGo 検索 ===")
	results, err := duckduckgoSearch("AIエージェント 実践 Go", 3)
	if err != nil {
		panic(err)
	}

	for i, r := range results {
		fmt.Printf("\n[%d] %s\n", i+1, r.Title)
		fmt.Printf("URL:       %s\n", r.URL)
		fmt.Printf("スニペット: %s\n", r.Snippet)
	}

	if len(results) == 0 {
		fmt.Println("検索結果が見つかりませんでした。")
		return
	}

	// 最初のURLをフェッチ
	firstURL := results[0].URL
	fmt.Printf("\n=== Web フェッチ: %s ===\n", firstURL)

	resp, err := http.Get(firstURL)
	if err != nil {
		fmt.Printf("フェッチエラー: %v\n", err)
		return
	}
	defer resp.Body.Close()

	fmt.Printf("ステータスコード: %d\n", resp.StatusCode)

	body, err := io.ReadAll(io.LimitReader(resp.Body, 500))
	if err != nil {
		fmt.Printf("読み込みエラー: %v\n", err)
		return
	}
	fmt.Printf("先頭500バイト:\n%s\n", string(body))
}

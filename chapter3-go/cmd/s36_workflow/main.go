// 3.6 LangGraph 相当のエージェントワークフロー
// StateGraph パターンを Go で直接実装する。
// Plan → Generate → Reflect のループを反復し、一定回数後に終了する。
package main

import (
	"fmt"

	"github.com/bellwood4486/genai-agent-advanced-book/chapter3-go/internal/envutil"
)

// AgentState はエージェントの状態を保持する。
type AgentState struct {
	Input     string
	Plans     []string
	Feedbacks []string
	Output    string
	Iteration int
}

// planNode はブログ記事のアウトラインを作成する。
func planNode(state *AgentState) {
	state.Plans = []string{
		"1. はじめに",
		"2. LangGraph の基本概念",
		"3. シンプルなワークフローの例",
		"4. まとめ",
	}
	fmt.Println("[planner] アウトラインを作成しました")
	fmt.Printf("  計画: %v\n", state.Plans)
}

// generationNode はイテレーションに応じてコンテンツを生成する。
func generationNode(state *AgentState) {
	state.Iteration++
	switch state.Iteration {
	case 1:
		state.Output = "LangGraph は複雑なエージェントワークフローを構築するためのフレームワークです。"
	case 2:
		state.Output += " ステートグラフを使って状態管理と条件分岐を実現します。"
	case 3:
		state.Output += " 例: graph.add_node('agent', agent_fn); graph.add_edge(START, 'agent')"
	default:
		state.Output += " 以上が LangGraph の基本的な使い方です。"
	}
	fmt.Printf("[generator] イテレーション %d: コンテンツを生成しました\n", state.Iteration)
	fmt.Printf("  出力 (先頭50文字): %.50s...\n", state.Output)
}

// reflectionNode はフィードバックを生成する。
func reflectionNode(state *AgentState) {
	var feedback string
	switch state.Iteration {
	case 1:
		feedback = "具体的なコード例を追加してください"
	case 2:
		feedback = "コード例の説明を追加してください"
	case 3:
		feedback = "まとめセクションを充実させてください"
	default:
		feedback = "全体的に改善が必要です"
	}
	state.Feedbacks = append(state.Feedbacks, feedback)
	fmt.Printf("[reflector] フィードバック: %s\n", feedback)
}

// shouldContinue はループを続けるか終了するかを判定する。
func shouldContinue(state *AgentState) string {
	if state.Iteration > 3 {
		return "END"
	}
	return "reflector"
}

func main() {
	envutil.Load()

	state := &AgentState{
		Input: "LangGraph についてのブログ記事を書いてください",
	}

	fmt.Printf("=== ワークフロー開始 ===\n入力: %s\n\n", state.Input)

	// ステップ1: プランナーノード
	planNode(state)
	fmt.Println()

	// ステップ2以降: ジェネレーター → 条件分岐 → リフレクター のループ
	for {
		generationNode(state)

		next := shouldContinue(state)
		fmt.Printf("[router] 次のノード: %s\n\n", next)

		if next == "END" {
			break
		}

		reflectionNode(state)
		fmt.Println()
	}

	fmt.Println("=== ワークフロー完了 ===")
	fmt.Printf("総イテレーション数: %d\n", state.Iteration)
	fmt.Printf("\n最終出力:\n%s\n", state.Output)
	fmt.Printf("\nフィードバック履歴:\n")
	for i, fb := range state.Feedbacks {
		fmt.Printf("  %d. %s\n", i+1, fb)
	}
}

import asyncio
from contextlib import asynccontextmanager
from functools import lru_cache

from fastapi import Depends, FastAPI
from pydantic import BaseModel

from src.agent import HelpDeskAgent
from src.configs import Settings
from src.tools.search_xyz_manual import search_xyz_manual
from src.tools.search_xyz_qa import search_xyz_qa


# @lru_cache: 同じ引数での呼び出し結果をキャッシュする。
# 引数なしなので、Settingsインスタンスはアプリ全体で1つだけ生成される（シングルトン相当）。
# Settings()は内部で環境変数や.envファイルを読み込む（Pydantic Settingsの仕組み）。
@lru_cache
def get_settings() -> Settings:
    return Settings()


# Depends(): FastAPIの依存性注入（DI）の仕組み。
# エンドポイント関数の引数にDepends(関数)を指定すると、FastAPIがその関数を自動で呼び出し、
# 戻り値を引数に渡してくれる。テスト時にdependency_overridesで差し替え可能。
# noqa: B008 — Pythonのlintルール「関数のデフォルト引数にミュータブルな値を使うな」の警告を抑制。
# Depends()はFastAPIが特別に扱うため、通常のデフォルト引数とは異なり問題ない。
def get_agent(settings: Settings = Depends(get_settings)) -> HelpDeskAgent:  # noqa: B008
    return HelpDeskAgent(settings=settings, tools=[search_xyz_manual, search_xyz_qa])


# lifespan: FastAPIアプリの起動時・終了時に実行される処理を定義するコンテキストマネージャ。
# yieldの前が起動時処理、後が終了時処理。現在は何もしていないが、
# 将来的にDBクライアントの初期化・クローズなどをここに追加する。
# @asynccontextmanager: async def + yieldで非同期コンテキストマネージャを作るデコレータ。
@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Helpdesk Agent API", lifespan=lifespan)


# Pydantic BaseModel: リクエスト/レスポンスのスキーマ定義。
# FastAPIがこのクラスを使ってJSONの自動バリデーションとシリアライズを行う。
# フィールドの型が合わなければ422エラーを自動で返す。
class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    answer: str


@app.get("/health")
async def health():
    return {"status": "ok"}


# response_model: レスポンスのJSONスキーマを指定。OpenAPIドキュメント生成にも使われる。
@app.post("/v1/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, agent: HelpDeskAgent = Depends(get_agent)) -> ChatResponse:  # noqa: B008
    # asyncio.to_thread: 同期関数（agent.run_agent）を別スレッドで実行し、
    # 非同期的に待機する。これによりFastAPIのイベントループをブロックしない。
    # LangGraphのagent.run_agentは同期関数のため、この変換が必要。
    result = await asyncio.to_thread(agent.run_agent, request.message)
    return ChatResponse(answer=result.answer)

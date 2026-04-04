import asyncio
from contextlib import asynccontextmanager
from functools import lru_cache

from fastapi import Depends, FastAPI
from pydantic import BaseModel

from src.agent import HelpDeskAgent
from src.configs import Settings
from src.tools.search_xyz_manual import search_xyz_manual
from src.tools.search_xyz_qa import search_xyz_qa


@lru_cache
def get_settings() -> Settings:
    return Settings()


def get_agent(settings: Settings = Depends(get_settings)) -> HelpDeskAgent:  # noqa: B008
    return HelpDeskAgent(settings=settings, tools=[search_xyz_manual, search_xyz_qa])


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Helpdesk Agent API", lifespan=lifespan)


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    answer: str


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/v1/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, agent: HelpDeskAgent = Depends(get_agent)) -> ChatResponse:  # noqa: B008
    result = await asyncio.to_thread(agent.run_agent, request.message)
    return ChatResponse(answer=result.answer)

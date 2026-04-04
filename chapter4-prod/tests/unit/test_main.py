from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from src.main import app, get_agent
from src.models import AgentResult, Plan


# @pytest.fixture: テスト関数に共通の前準備オブジェクトを提供する仕組み。
# テスト関数の引数名がfixtureの関数名と一致すると、pytestが自動で渡してくれる。
@pytest.fixture
def mock_agent():
    # MagicMock: 任意の属性・メソッド呼び出しを受け付けるモックオブジェクト。
    # ここではHelpDeskAgentの代替として使い、run_agentの戻り値を固定する。
    agent = MagicMock()
    agent.run_agent.return_value = AgentResult(
        question="test",
        plan=Plan(subtasks=["step1"]),
        subtasks=[],
        answer="テスト回答です。",
    )
    return agent


@pytest.fixture
def client(mock_agent):
    # dependency_overrides: FastAPIのDI差し替え機能。
    # get_agentの代わりにmock_agentを返すlambdaを登録することで、
    # テスト中はLLMや検索エンジンに接触せず純粋にAPIレイヤーだけを検証できる。
    app.dependency_overrides[get_agent] = lambda: mock_agent
    # TestClient: FastAPIをHTTPサーバとして起動せずに直接リクエストを投げられるテスト用クライアント。
    # with文で使うとlifespanの起動/終了処理も呼ばれる。
    with TestClient(app) as c:
        yield c
    # テスト後にオーバーライドをクリア。残すと他のテストに影響する。
    app.dependency_overrides.clear()


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_chat_ok(client, mock_agent):
    response = client.post("/v1/chat", json={"message": "XYZシステムのエラーコードE001とは？"})
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert data["answer"] == "テスト回答です。"
    mock_agent.run_agent.assert_called_once_with("XYZシステムのエラーコードE001とは？")


def test_chat_missing_message(client):
    response = client.post("/v1/chat", json={})
    assert response.status_code == 422


def test_chat_invalid_body(client):
    response = client.post("/v1/chat", content="not-json", headers={"Content-Type": "application/json"})
    assert response.status_code == 422

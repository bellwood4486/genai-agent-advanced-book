from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from src.main import app, get_agent
from src.models import AgentResult, Plan


@pytest.fixture
def mock_agent():
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
    app.dependency_overrides[get_agent] = lambda: mock_agent
    with TestClient(app) as c:
        yield c
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

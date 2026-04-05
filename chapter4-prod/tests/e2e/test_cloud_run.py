"""
Cloud Run E2E スモークテスト。

事前に以下の環境変数を設定してから実行する:
  export CLOUD_RUN_URL=$(terraform -chdir=infra output -raw cloud_run_url)
  uv run pytest tests/e2e/test_cloud_run.py -v

CLOUD_RUN_URL が未設定の場合はテストをスキップする。
OpenAI API 呼び出しとコールドスタートが発生するため、タイムアウトを 60 秒に設定している。
"""

import os

import httpx
import pytest

# terraform output -raw cloud_run_url の値を環境変数から取得する。
# CI/CD では設定不要（E2E テストは手動実行のみ）。
CLOUD_RUN_URL = os.getenv("CLOUD_RUN_URL", "").rstrip("/")


@pytest.fixture(autouse=True)
def skip_if_no_url():
    """CLOUD_RUN_URL が未設定の場合はテストをスキップする。"""
    if not CLOUD_RUN_URL:
        pytest.skip("CLOUD_RUN_URL is not set — run: export CLOUD_RUN_URL=$(terraform -chdir=infra output -raw cloud_run_url)")


def test_health():
    """GET /health が 200 と {"status": "ok"} を返すことを確認する。"""
    response = httpx.get(f"{CLOUD_RUN_URL}/health", timeout=30)
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_chat():
    """POST /v1/chat に質問を送り、非空の回答が返ることを確認する。

    LLM 呼び出しとコールドスタートを考慮し、タイムアウトを 60 秒に設定する。
    """
    payload = {"message": "XYZシステムのログインエラーの対処方法を教えてください"}
    response = httpx.post(
        f"{CLOUD_RUN_URL}/v1/chat",
        json=payload,
        # コールドスタート（スケールゼロからの起動）+ LLM 推論を考慮したタイムアウト
        timeout=60,
    )
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert len(data["answer"]) > 0

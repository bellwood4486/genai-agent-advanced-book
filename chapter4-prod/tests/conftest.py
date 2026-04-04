import pytest


@pytest.fixture(autouse=False)
def mock_required_env(monkeypatch):
    """Provide required env vars so Settings() can be constructed without a .env file."""
    monkeypatch.setenv("OPENAI_API_KEY", "test-openai-key")
    monkeypatch.setenv("OPENAI_API_BASE", "https://api.openai.com/v1")
    monkeypatch.setenv("OPENAI_MODEL", "gpt-4o-2024-08-06")

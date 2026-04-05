import pytest

from src.configs import Settings


@pytest.fixture
def base_env(monkeypatch):
    monkeypatch.setenv("OPENAI_API_KEY", "test-key")
    monkeypatch.setenv("OPENAI_API_BASE", "https://api.openai.com/v1")
    monkeypatch.setenv("OPENAI_MODEL", "gpt-4o-2024-08-06")
    # Prevent loading from .env file during tests
    monkeypatch.delenv("ELASTICSEARCH_URL", raising=False)
    monkeypatch.delenv("ELASTIC_API_KEY", raising=False)
    monkeypatch.delenv("QDRANT_URL", raising=False)
    monkeypatch.delenv("QDRANT_API_KEY", raising=False)


def test_settings_builds_with_required_fields(base_env):
    settings = Settings()
    assert settings.openai_api_key == "test-key"


def test_elasticsearch_url_default(base_env):
    settings = Settings()
    assert settings.elasticsearch_url == "http://localhost:9200"


def test_qdrant_url_default(base_env):
    settings = Settings()
    assert settings.qdrant_url == "http://localhost:6333"


def test_qdrant_api_key_default_is_none(base_env):
    settings = Settings()
    assert settings.qdrant_api_key is None


def test_elastic_api_key_default_is_none(base_env):
    # ローカル ES（認証なし）との互換性のためデフォルトは None
    settings = Settings()
    assert settings.elastic_api_key is None


def test_env_var_overrides_defaults(base_env, monkeypatch):
    monkeypatch.setenv("ELASTICSEARCH_URL", "https://my-es.cloud.example.com")
    monkeypatch.setenv("ELASTIC_API_KEY", "secret-elastic-key")
    monkeypatch.setenv("QDRANT_URL", "https://my-qdrant.cloud.example.com")
    monkeypatch.setenv("QDRANT_API_KEY", "secret-qdrant-key")

    settings = Settings()
    assert settings.elasticsearch_url == "https://my-es.cloud.example.com"
    assert settings.elastic_api_key == "secret-elastic-key"
    assert settings.qdrant_url == "https://my-qdrant.cloud.example.com"
    assert settings.qdrant_api_key == "secret-qdrant-key"

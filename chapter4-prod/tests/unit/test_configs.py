import pytest

from src.configs import Settings


@pytest.fixture
def base_env(monkeypatch):
    monkeypatch.setenv("OPENAI_API_KEY", "test-key")
    monkeypatch.setenv("OPENAI_API_BASE", "https://api.openai.com/v1")
    monkeypatch.setenv("OPENAI_MODEL", "gpt-4o-2024-08-06")
    # Prevent loading from .env file during tests
    monkeypatch.delenv("ELASTICSEARCH_URL", raising=False)
    monkeypatch.delenv("ELASTIC_USERNAME", raising=False)
    monkeypatch.delenv("ELASTIC_PASSWORD", raising=False)
    monkeypatch.delenv("QDRANT_URL", raising=False)
    monkeypatch.delenv("QDRANT_API_KEY", raising=False)
    monkeypatch.delenv("GCS_BUCKET_NAME", raising=False)


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


def test_elastic_auth_defaults_are_none(base_env):
    # ローカル ES（認証なし）との互換性のためデフォルトは None
    settings = Settings()
    assert settings.elastic_username is None
    assert settings.elastic_password is None


def test_gcs_bucket_name_default_is_none(base_env):
    # GCS_BUCKET_NAME 未設定時はローカル data/ を使う（ローカル開発との後方互換）
    settings = Settings()
    assert settings.gcs_bucket_name is None


def test_gcs_bucket_name_is_set_via_env_var(base_env, monkeypatch):
    monkeypatch.setenv("GCS_BUCKET_NAME", "my-project-helpdesk-docs")
    settings = Settings()
    assert settings.gcs_bucket_name == "my-project-helpdesk-docs"


def test_env_var_overrides_defaults(base_env, monkeypatch):
    monkeypatch.setenv("ELASTICSEARCH_URL", "https://my-es.cloud.example.com")
    monkeypatch.setenv("ELASTIC_USERNAME", "elastic-user")
    monkeypatch.setenv("ELASTIC_PASSWORD", "secret-elastic-password")
    monkeypatch.setenv("QDRANT_URL", "https://my-qdrant.cloud.example.com")
    monkeypatch.setenv("QDRANT_API_KEY", "secret-qdrant-key")

    settings = Settings()
    assert settings.elasticsearch_url == "https://my-es.cloud.example.com"
    assert settings.elastic_username == "elastic-user"
    assert settings.elastic_password == "secret-elastic-password"
    assert settings.qdrant_url == "https://my-qdrant.cloud.example.com"
    assert settings.qdrant_api_key == "secret-qdrant-key"

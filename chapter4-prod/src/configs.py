from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    openai_api_key: str
    openai_api_base: str
    openai_model: str

    elasticsearch_url: str = "http://localhost:9200"
    # Elastic Cloud Serverless は Basic 認証（ユーザー名 + パスワード）を使う。
    # ec_elasticsearch_project.credentials で自動生成されるユーザー名を渡す。
    # ローカルの Elasticsearch（認証なし）との互換性を保つため None をデフォルトにする。
    elastic_username: str | None = None
    # Elastic Cloud Serverless の Basic 認証パスワード（Secret Manager で管理）。
    # 環境変数名は ELASTIC_API_KEY だが値は Elasticsearch パスワード。
    elastic_api_key: str | None = None
    qdrant_url: str = "http://localhost:6333"
    qdrant_api_key: str | None = None

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

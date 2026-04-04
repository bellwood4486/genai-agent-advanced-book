from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    openai_api_key: str
    openai_api_base: str
    openai_model: str

    elasticsearch_url: str = "http://localhost:9200"
    qdrant_url: str = "http://localhost:6333"
    qdrant_api_key: str | None = None

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

from elasticsearch import Elasticsearch
from qdrant_client import QdrantClient

from src.configs import Settings


def delete_es_index(es: Elasticsearch, index_name: str) -> None:
    # インデックスの削除
    if es.indices.exists(index=index_name):
        es.indices.delete(index=index_name)
        print(f"Index '{index_name}' has been deleted.")
    else:
        print(f"Index '{index_name}' does not exist.")


def delete_qdrant_index(qdrant_client: QdrantClient, collection_name: str) -> None:

    if qdrant_client.collection_exists(collection_name=collection_name):
        # qdrantでインデックスを削除
        qdrant_client.delete_collection("documents")
        print(f"Collection '{collection_name}' has been deleted.")
    else:
        print(f"Collection '{collection_name}' does not exist.")


if __name__ == "__main__":
    settings = Settings()
    # Elastic Cloud Serverless は Basic 認証（ユーザー名 + パスワード）を使う。
    # elastic_username と elastic_api_key（パスワード）がともに設定されている場合のみ
    # basic_auth を渡す。ローカル ES（認証なし）との互換性を維持するため None はスキップ。
    es_kwargs: dict = {"hosts": [settings.elasticsearch_url]}
    if settings.elastic_username and settings.elastic_password:
        es_kwargs["basic_auth"] = (settings.elastic_username, settings.elastic_password)
    es = Elasticsearch(**es_kwargs)
    qdrant_kwargs: dict = {"url": settings.qdrant_url}
    if settings.qdrant_api_key:
        qdrant_kwargs["api_key"] = settings.qdrant_api_key
    qdrant_client = QdrantClient(**qdrant_kwargs)

    index_name = "documents"

    delete_es_index(es=es, index_name=index_name)

    delete_qdrant_index(qdrant_client=qdrant_client, collection_name=index_name)

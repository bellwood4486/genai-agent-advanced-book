"""Elastic Cloud Serverless および Qdrant Cloud のインテグレーションテスト。

Terraform でプロビジョニングされた検索サービスに実際に接続し、
インデックス作成・ドキュメント投入・検索の基本動作を確認する。

前提条件:
  - `terraform apply` を infra/ で実行済みであること
  - 以下の環境変数を terraform output から設定しておくこと

必要な環境変数:
  ELASTICSEARCH_URL       : terraform output -raw elasticsearch_endpoint
  ELASTICSEARCH_USERNAME  : terraform output -json elasticsearch_credentials | jq -r .username
  ELASTICSEARCH_PASSWORD  : terraform output -json elasticsearch_credentials | jq -r .password
  QDRANT_URL              : terraform output -raw qdrant_endpoint
  QDRANT_API_KEY          : terraform output -raw qdrant_api_key
"""

import os
import uuid

import pytest
from elasticsearch import Elasticsearch
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def es_client():
    """Elastic Cloud Serverless への Elasticsearch クライアント。
    環境変数が未設定の場合はテストをスキップする。
    """
    url = os.environ.get("ELASTICSEARCH_URL")
    username = os.environ.get("ELASTICSEARCH_USERNAME")
    password = os.environ.get("ELASTICSEARCH_PASSWORD")
    if not all([url, username, password]):
        pytest.skip(
            "Elasticsearch cloud 接続情報が環境変数に設定されていません。"
            " terraform output から ELASTICSEARCH_URL / ELASTICSEARCH_USERNAME"
            " / ELASTICSEARCH_PASSWORD を設定してください。"
        )
    # basic_auth: (username, password) のタプルで Basic 認証を行う
    return Elasticsearch(url, basic_auth=(username, password))


@pytest.fixture(scope="module")
def qdrant_client_cloud():
    """Qdrant Cloud へのクライアント。
    環境変数が未設定の場合はテストをスキップする。
    """
    url = os.environ.get("QDRANT_URL")
    api_key = os.environ.get("QDRANT_API_KEY")
    if not all([url, api_key]):
        pytest.skip(
            "Qdrant Cloud 接続情報が環境変数に設定されていません。"
            " terraform output から QDRANT_URL / QDRANT_API_KEY を設定してください。"
        )
    return QdrantClient(url=url, api_key=api_key)


# テストごとにユニークなインデックス/コレクション名を使い、並列実行時の衝突を避ける
_UNIQUE_SUFFIX = uuid.uuid4().hex[:8]
TEST_ES_INDEX = f"test-integration-{_UNIQUE_SUFFIX}"
TEST_QDRANT_COLLECTION = f"test-integration-{_UNIQUE_SUFFIX}"


# ---------------------------------------------------------------------------
# Elasticsearch テスト
# ---------------------------------------------------------------------------


class TestElasticCloudServerless:
    """Elastic Cloud Serverless への接続・インデックス操作・検索を検証する。"""

    def test_cluster_info(self, es_client):
        """クラスタに接続してバージョン情報が取得できることを確認する。"""
        info = es_client.info()
        # Elasticsearch のバージョン情報が含まれていること
        assert "version" in info
        assert info["version"]["number"]  # バージョン文字列が空でないこと

    def test_index_and_search(self, es_client):
        """ドキュメントをインデックスし、全文検索で取得できることを確認する。
        テスト後にインデックスを削除してクリーンアップする。
        """
        try:
            # インデックス作成（既存の場合は ignore=400 でスキップ）
            es_client.indices.create(index=TEST_ES_INDEX, ignore=400)

            # ドキュメントを投入する。refresh="wait_for" によりインデックス反映を待つ。
            doc = {
                "content": "XYZ システム エラーコード E-1001 の対処法",
                "file_name": "manual.pdf",
            }
            es_client.index(
                index=TEST_ES_INDEX, id="doc-1", document=doc, refresh="wait_for"
            )

            # 全文検索で投入したドキュメントが取得できること
            result = es_client.search(
                index=TEST_ES_INDEX,
                body={"query": {"match": {"content": "エラーコード E-1001"}}},
            )
            assert result["hits"]["total"]["value"] >= 1
            assert result["hits"]["hits"][0]["_source"]["file_name"] == "manual.pdf"
        finally:
            # テスト後にインデックスを削除する（ignore=[404] で存在しない場合も無視）
            es_client.indices.delete(index=TEST_ES_INDEX, ignore=[404])


# ---------------------------------------------------------------------------
# Qdrant テスト
# ---------------------------------------------------------------------------


class TestQdrantCloud:
    """Qdrant Cloud への接続・コレクション操作・ベクトル検索を検証する。"""

    def test_cluster_health(self, qdrant_client_cloud):
        """クラスタに接続してコレクション一覧が取得できることを確認する。"""
        # get_collections() が例外なく完了すること
        collections = qdrant_client_cloud.get_collections()
        assert collections is not None

    def test_collection_crud_and_search(self, qdrant_client_cloud):
        """コレクション作成・ベクトル upsert・類似検索・削除の一連の流れを確認する。"""
        # テスト用に小さなベクトルサイズを使う（実際のアプリでは 1536 次元など）
        vector_size = 4

        try:
            # コレクション作成。vectors_config でベクトルの次元数と距離関数を指定する。
            # COSINE: コサイン類似度。テキスト埋め込みの比較によく使われる。
            qdrant_client_cloud.create_collection(
                collection_name=TEST_QDRANT_COLLECTION,
                vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
            )

            # ポイント（ベクトル + メタデータ）を upsert する
            qdrant_client_cloud.upsert(
                collection_name=TEST_QDRANT_COLLECTION,
                points=[
                    PointStruct(
                        id=1,
                        vector=[0.1, 0.2, 0.3, 0.4],
                        payload={
                            "file_name": "qa.csv",
                            "content": "パスワードリセットの方法",
                        },
                    )
                ],
            )

            # クエリベクトルに最も近いポイントを検索する
            results = qdrant_client_cloud.query_points(
                collection_name=TEST_QDRANT_COLLECTION,
                query=[0.1, 0.2, 0.3, 0.4],
                limit=1,
            )
            assert len(results.points) == 1
            assert results.points[0].payload["file_name"] == "qa.csv"
        finally:
            # テスト後にコレクションを削除する
            qdrant_client_cloud.delete_collection(
                collection_name=TEST_QDRANT_COLLECTION
            )

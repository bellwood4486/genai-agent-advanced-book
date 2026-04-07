"""GCS → Cloud Run Job → ES/Qdrant インデックス作成パイプラインのインテグレーションテスト。

GCS バケットにドキュメントをアップロードし、Cloud Run Job を手動実行して
インデックスが作成されることを確認する。

テスト専用のインデックス名（test-documents-<uuid>）を使用して Cloud Run Job を実行するため、
本番の "documents" インデックスには影響しない。

前提条件:
  - `terraform apply` を infra/ で実行済みであること
  - Docker イメージが Artifact Registry に push 済みであること
  - 以下の環境変数を設定しておくこと

必要な環境変数:
  GCS_BUCKET_NAME         : terraform output -raw gcs_bucket_name
  ELASTICSEARCH_URL       : terraform output -raw elasticsearch_endpoint
  ELASTICSEARCH_USERNAME  : terraform output -json elasticsearch_credentials | jq -r .username
  ELASTICSEARCH_PASSWORD  : terraform output -json elasticsearch_credentials | jq -r .password
  QDRANT_URL              : terraform output -raw qdrant_endpoint
  QDRANT_API_KEY          : terraform output -raw qdrant_api_key
  OPENAI_API_KEY          : OpenAI API キー（embedding 生成に必要）
"""

import os
import subprocess
import tempfile
import uuid

import pytest
from elasticsearch import Elasticsearch
from google.cloud import storage as gcs_storage
from qdrant_client import QdrantClient

# テスト専用のインデックス/コレクション名。実行ごとに一意な名前を生成し、
# 本番の "documents" インデックスと衝突しないようにする。
# test_search_cloud.py と同じパターン。
TEST_INDEX_NAME = f"test-documents-{uuid.uuid4().hex[:8]}"

# テスト用にアップロードする小さなサンプル CSV（Q&A 形式）
_SAMPLE_CSV_CONTENT = """question,answer
テストの質問1,テストの回答1
テストの質問2,テストの回答2
"""

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def gcs_bucket_name():
    name = os.environ.get("GCS_BUCKET_NAME")
    if not name:
        pytest.skip("GCS_BUCKET_NAME が設定されていません。terraform output -raw gcs_bucket_name で取得してください。")
    return name


@pytest.fixture(scope="module")
def es_client():
    url = os.environ.get("ELASTICSEARCH_URL")
    username = os.environ.get("ELASTICSEARCH_USERNAME")
    password = os.environ.get("ELASTICSEARCH_PASSWORD")
    if not all([url, username, password]):
        pytest.skip(
            "Elasticsearch 接続情報が環境変数に設定されていません。"
            " ELASTICSEARCH_URL / ELASTICSEARCH_USERNAME / ELASTICSEARCH_PASSWORD を設定してください。"
        )
    return Elasticsearch(url, basic_auth=(username, password))


@pytest.fixture(scope="module")
def qdrant_client_cloud():
    url = os.environ.get("QDRANT_URL")
    api_key = os.environ.get("QDRANT_API_KEY")
    if not all([url, api_key]):
        pytest.skip(
            "Qdrant Cloud 接続情報が環境変数に設定されていません。"
            " QDRANT_URL / QDRANT_API_KEY を設定してください。"
        )
    return QdrantClient(url=url, api_key=api_key)


# ---------------------------------------------------------------------------
# テスト
# ---------------------------------------------------------------------------


class TestIngestionPipeline:
    """GCS アップロード → Cloud Run Job 実行 → ES/Qdrant インデックス確認のパイプラインテスト。"""

    def test_upload_and_ingest(self, gcs_bucket_name, es_client, qdrant_client_cloud):
        """テスト用 CSV を GCS にアップロードし、Job を実行してインデックスが作成されることを確認する。

        テスト専用インデックス名（TEST_INDEX_NAME）を Cloud Run Job に渡して実行するため、
        本番の "documents" インデックスは変更されない。
        テスト後に GCS オブジェクト・テスト用 ES インデックス・Qdrant コレクションをクリーンアップする。
        """
        uploaded_blob_name = "test_ingestion_sample.csv"
        gcs_client = gcs_storage.Client()
        bucket = gcs_client.bucket(gcs_bucket_name)
        blob = bucket.blob(uploaded_blob_name)

        try:
            # 1. サンプル CSV を GCS にアップロードする
            with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
                f.write(_SAMPLE_CSV_CONTENT)
                tmp_path = f.name
            blob.upload_from_filename(tmp_path)
            os.unlink(tmp_path)
            print(f"Uploaded: gs://{gcs_bucket_name}/{uploaded_blob_name}")

            # 2. Cloud Run Job を実行する（gcloud CLI）
            # --wait: ジョブの完了または失敗まで待機する（非同期にしない）
            # --args: この execution 限定で create_index.py に CLI 引数を渡す。
            #   Cloud Run では command（ENTRYPOINT）の後に args（CMD）が結合されて実行される。
            #   つまり "python -m src.scripts.create_index --index-name <name>" として動く。
            #   Job 定義自体は変更されず、本番インデックス名（"documents"）は維持される。
            result = subprocess.run(
                [
                    "gcloud",
                    "run",
                    "jobs",
                    "execute",
                    "helpdesk-ingestion",
                    "--region",
                    "asia-northeast1",
                    f"--args=--index-name,{TEST_INDEX_NAME}",
                    "--wait",
                ],
                capture_output=True,
                text=True,
                timeout=700,  # Job のタイムアウト（600s）より少し長く設定
            )
            print("gcloud stdout:", result.stdout)
            print("gcloud stderr:", result.stderr)
            assert result.returncode == 0, f"Cloud Run Job が失敗しました: {result.stderr}"

            # 3. ES にテスト用インデックスが存在し、ドキュメントが含まれることを確認する
            assert es_client.indices.exists(index=TEST_INDEX_NAME), (
                f"ES インデックス {TEST_INDEX_NAME!r} が存在しません"
            )
            es_client.indices.refresh(index=TEST_INDEX_NAME)
            count = es_client.count(index=TEST_INDEX_NAME)
            assert count["count"] > 0, f"ES インデックス {TEST_INDEX_NAME!r} にドキュメントがありません"
            print(f"ES index {TEST_INDEX_NAME!r} has {count['count']} documents")

            # 4. Qdrant にテスト用コレクションが存在し、ポイントが含まれることを確認する
            assert qdrant_client_cloud.collection_exists(
                collection_name=TEST_INDEX_NAME
            ), f"Qdrant コレクション {TEST_INDEX_NAME!r} が存在しません"
            collection_info = qdrant_client_cloud.get_collection(collection_name=TEST_INDEX_NAME)
            # points_count: コレクション内のポイント数
            assert collection_info.points_count > 0, f"Qdrant コレクション {TEST_INDEX_NAME!r} にポイントがありません"
            print(f"Qdrant collection {TEST_INDEX_NAME!r} has {collection_info.points_count} points")

        finally:
            # クリーンアップ: GCS オブジェクト、テスト用 ES インデックス、Qdrant コレクションを削除する
            # 本番の "documents" インデックスは削除しない。
            try:
                blob.delete()
                print(f"Deleted GCS object: gs://{gcs_bucket_name}/{uploaded_blob_name}")
            except Exception as e:
                print(f"GCS クリーンアップ失敗（無視）: {e}")

            try:
                es_client.indices.delete(index=TEST_INDEX_NAME, ignore=[404])
                print(f"Deleted ES index: {TEST_INDEX_NAME}")
            except Exception as e:
                print(f"ES クリーンアップ失敗（無視）: {e}")

            try:
                qdrant_client_cloud.delete_collection(collection_name=TEST_INDEX_NAME)
                print(f"Deleted Qdrant collection: {TEST_INDEX_NAME}")
            except Exception as e:
                print(f"Qdrant クリーンアップ失敗（無視）: {e}")

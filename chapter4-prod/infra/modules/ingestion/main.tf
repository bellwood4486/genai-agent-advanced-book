# Cloud Run v2 Job — GCS のドキュメントから ES/Qdrant インデックスを作成する。
#
# Cloud Run "Job" は Cloud Run "Service" と異なり、HTTP リクエストを待たずに
# 実行 → 完了 → 終了するバッチ処理向けリソース。
# 1 回の実行を「Execution」と呼び、gcloud や API で手動トリガーできる。
# Increment 7 では Eventarc で GCS アップロードをトリガーに自動実行する。
#
# Cloud Run Service との主な違い:
#   - Service: HTTP リクエスト駆動、常時起動可能、URL を持つ
#   - Job: タスク駆動、実行 → 完了 → 終了、URL を持たない

resource "google_cloud_run_v2_job" "ingestion" {
  project  = var.project_id
  name     = "helpdesk-ingestion"
  location = var.region

  template {
    template {
      # Cloud Run Service と同じ SA を再利用する（学習用プロジェクトのためシンプルさ優先）。
      # 本番環境ではジョブ専用の SA を作り、最小権限を徹底すべき。
      service_account = var.service_account_email

      containers {
        image = var.image

        # command: Dockerfile の CMD（uvicorn）を上書きする。
        # 同じイメージを使いつつ、Web サーバーではなく create_index.py を実行する。
        command = ["python", "-m", "src.scripts.create_index"]

        # --- 平文の環境変数（非機密） ---
        env {
          name  = "GCS_BUCKET_NAME"
          value = var.gcs_bucket_name
        }
        env {
          name  = "ELASTICSEARCH_URL"
          value = var.elasticsearch_url
        }
        env {
          name  = "QDRANT_URL"
          value = var.qdrant_url
        }
        # Elastic Cloud Serverless の Basic 認証ユーザー名（機密ではないため平文）。
        env {
          name  = "ELASTIC_USERNAME"
          value = var.elastic_username
        }
        env {
          name  = "OPENAI_API_BASE"
          value = var.openai_api_base
        }
        env {
          name  = "OPENAI_MODEL"
          value = var.openai_model
        }

        # --- Secret Manager 参照（cloud-run モジュールと同じパターン） ---
        # value_source.secret_key_ref を使うと、Job 起動時に Secret Manager から
        # 最新バージョンの値を取得して環境変数にセットする。
        env {
          name = "OPENAI_API_KEY"
          value_source {
            secret_key_ref {
              secret  = var.secret_ids["openai-api-key"]
              version = "latest"
            }
          }
        }
        env {
          name = "ELASTIC_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = var.secret_ids["elastic-password"]
              version = "latest"
            }
          }
        }
        env {
          name = "QDRANT_API_KEY"
          value_source {
            secret_key_ref {
              secret  = var.secret_ids["qdrant-api-key"]
              version = "latest"
            }
          }
        }

        resources {
          limits = {
            cpu    = "1"
            # PDF 解析と OpenAI Embedding API 呼び出しのためメモリを確保。
            memory = "512Mi"
          }
        }
      }

      # PDF 解析 + OpenAI embedding API 呼び出しがあるため Service（300s）より長く設定。
      timeout = "600s"

      # ジョブ失敗時のリトライ回数。
      # create_index.py は冪等（既存インデックスをスキップ）なため安全にリトライできる。
      max_retries = 1
    }
  }
}

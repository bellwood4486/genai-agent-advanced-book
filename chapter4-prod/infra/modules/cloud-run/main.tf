# Cloud Run v2 サービス — ヘルプデスクエージェントの HTTP API をデプロイする。
#
# Cloud Run v2 API（google_cloud_run_v2_service）は、
# 旧 v1 API（google_cloud_run_service）の後継で公式推奨。
# Direct VPC Egress（VPC ネットワークへの直接通信）、
# GPU サポートなど v2 固有の機能が利用できる。

resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  name     = "helpdesk-agent"
  location = var.region

  template {
    # Cloud Run がコンテナを起動する際に使用するサービスアカウント。
    # デフォルトの Compute Engine SA ではなく最小権限 SA を指定することで、
    # 不要な権限を持たせない（Principle of Least Privilege）。
    service_account = var.service_account_email

    containers {
      image = var.image

      # --- 平文の環境変数（非機密） ---
      # 検索エンジンのエンドポイント URL と OpenAI の設定を環境変数で渡す。
      # API キーなどの機密値は後述の secret_key_ref で渡す。
      env {
        name  = "ELASTICSEARCH_URL"
        value = var.elasticsearch_url
      }
      env {
        name  = "QDRANT_URL"
        value = var.qdrant_url
      }
      # Elastic Cloud Serverless の Basic 認証ユーザー名。
      # パスワードは ELASTIC_API_KEY として Secret Manager から取得する。
      # ユーザー名は機密ではないため平文 env var として渡す。
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

      # --- Secret Manager 参照の環境変数（機密） ---
      # value_source.secret_key_ref を使うと、Cloud Run が起動時に Secret Manager から
      # 最新バージョンの値を取得して環境変数にセットする。
      # アプリコードに秘密情報をハードコードせずに済む。
      # version = "latest" で常に最新バージョンを参照する。
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
        name = "ELASTIC_API_KEY"
        value_source {
          secret_key_ref {
            secret  = var.secret_ids["elastic-api-key"]
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
        # LLM 呼び出しを含む推論処理は CPU が必要。
        # memory はモデルのロードと依存ライブラリ（LangGraph 等）のために 512Mi を確保。
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      # スタートアッププローブ: コンテナが起動完了するまでトラフィックを送らない。
      # Cloud Run は初期リクエスト前にこのプローブを使ってヘルスチェックを行う。
      # /health エンドポイントは src/main.py で定義済み。
      startup_probe {
        http_get {
          path = "/health"
        }
        # 最大待機時間 = failure_threshold * period_seconds = 10 * 10 = 100秒
        # 依存ライブラリが多いため、コールドスタートに余裕を持たせる。
        failure_threshold = 10
        period_seconds    = 10
      }
    }

    scaling {
      # min = 0: リクエストがない時はコンテナを 0 台まで落とす（スケールトゥゼロ）。
      # 学習目的のため、アイドル時のコスト削減を優先する。
      # デメリット: 初回リクエスト時にコールドスタートが発生する（数秒〜数十秒）。
      min_instance_count = 0
      # max = 1: 同時実行数を制限し、外部 API（OpenAI/Elastic/Qdrant）への
      # 過剰リクエストを防ぐ。学習用途では 1 台で十分。
      max_instance_count = 1
    }

    # LLM 推論は時間がかかるため、デフォルト（60秒）より長いタイムアウトを設定。
    # 複数ツール呼び出しが発生する場合も 300秒 以内に完了することを想定。
    timeout = "300s"
  }
}

# IAM: 未認証アクセスの許可
# テスト目的のため allUsers（認証不要）で公開する。
# 本番運用する場合はここを削除し、Cloud IAP や認証ヘッダーによるアクセス制御を追加すること。
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

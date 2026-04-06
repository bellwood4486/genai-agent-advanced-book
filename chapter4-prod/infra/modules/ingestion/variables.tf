variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "GCP リージョン"
  type        = string
}

variable "image" {
  description = <<-EOT
    Cloud Run Job で実行するコンテナイメージの完全修飾 URL。
    Cloud Run サービスと同じイメージを再利用し、command でエントリポイントを切り替える。
    例: asia-northeast1-docker.pkg.dev/my-project/helpdesk/helpdesk-agent:latest
  EOT
  type        = string
}

variable "service_account_email" {
  description = "Cloud Run Job が使用するサービスアカウント（Secret Manager + GCS アクセス権限付き）"
  type        = string
}

variable "gcs_bucket_name" {
  description = "ドキュメントが格納された GCS バケット名（create_index.py の GCS_BUCKET_NAME 環境変数に渡す）"
  type        = string
}

variable "elasticsearch_url" {
  description = "Elasticsearch エンドポイント URL"
  type        = string
}

variable "elastic_username" {
  description = "Elasticsearch Basic 認証ユーザー名（Elastic Cloud Serverless が自動生成）"
  type        = string
}

variable "qdrant_url" {
  description = "Qdrant Cloud エンドポイント URL"
  type        = string
}

variable "openai_api_base" {
  description = "OpenAI API ベース URL"
  type        = string
}

variable "openai_model" {
  description = "使用する OpenAI モデル名"
  type        = string
}

variable "secret_ids" {
  description = <<-EOT
    Secret Manager シークレット ID マップ。
    キー: openai-api-key, elastic-password, qdrant-api-key
    値: projects/<project>/secrets/<name> 形式の完全修飾 ID
    cloud-run モジュールと同じマップを渡す。
  EOT
  type        = map(string)
}

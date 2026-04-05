variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "image" {
  description = <<-EOT
    デプロイするコンテナイメージの完全修飾 URL。
    例: asia-northeast1-docker.pkg.dev/<project>/helpdesk/helpdesk-agent:latest
  EOT
  type = string
}

variable "service_account_email" {
  description = "Cloud Run サービスが使用するサービスアカウントのメールアドレス（最小権限 SA）"
  type        = string
}

variable "elasticsearch_url" {
  description = "Elastic Cloud Serverless の Elasticsearch エンドポイント URL"
  type        = string
}

variable "elastic_username" {
  description = <<-EOT
    Elastic Cloud Serverless の Basic 認証ユーザー名。
    ec_elasticsearch_project.credentials.username から取得する。
    パスワード（elastic_api_key）と組み合わせて basic_auth に使う。
  EOT
  type = string
}

variable "qdrant_url" {
  description = "Qdrant Cloud クラスタのエンドポイント URL"
  type        = string
}

variable "openai_api_base" {
  description = "OpenAI API のベース URL"
  type        = string
}

variable "openai_model" {
  description = "使用する OpenAI モデル名"
  type        = string
}

variable "secret_ids" {
  description = <<-EOT
    Secret Manager のシークレット完全修飾 ID のマップ。
    キー: "openai-api-key", "elastic-api-key", "qdrant-api-key"
    値: projects/<project>/secrets/<name> 形式
  EOT
  type = map(string)
}

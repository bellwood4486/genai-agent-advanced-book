variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "elastic_api_key" {
  description = <<-EOT
    Elasticsearch への認証パスワード。
    Elastic Cloud Serverless がプロジェクト作成時に自動生成する credentials.password の値。
    Cloud Run から Elasticsearch API にアクセスする際の Basic 認証に使用する。
  EOT
  type        = string
  sensitive   = true
}

variable "qdrant_api_key" {
  description = <<-EOT
    Qdrant Cloud データベース API キー。
    Qdrant Cloud がクラスタ作成時に自動生成する認証トークン。
    Cloud Run から Qdrant API にアクセスする際の Bearer 認証に使用する。
  EOT
  type        = string
  sensitive   = true
}

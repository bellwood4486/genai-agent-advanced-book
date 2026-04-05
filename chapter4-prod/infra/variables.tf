variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast1"
}

variable "elastic_api_key" {
  description = "Elastic Cloud API key"
  type        = string
  sensitive   = true
}

variable "qdrant_cloud_api_key" {
  description = "Qdrant Cloud API key"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key (stored in Secret Manager)"
  type        = string
  sensitive   = true
}

variable "qdrant_cloud_account_id" {
  description = "Qdrant Cloud account ID（Qdrant Cloud コンソールの URL に表示される）"
  type        = string
}

variable "qdrant_region" {
  description = <<-EOT
    Qdrant Cloud クラスタを配置するリージョン。
    GCP の var.region とは独立して設定できる。
    Free Tier が利用可能なリージョンに限られる点に注意。
    利用可能リージョンは Qdrant Cloud コンソールの「Create Cluster」画面で確認できる。
    （例: us-east4, europe-west3）
  EOT
  type        = string
  default     = "us-east4"
}

variable "elastic_region" {
  description = <<-EOT
    Elastic Cloud Serverless プロジェクトを配置するリージョン ID。
    GCP の var.region とは独立して設定できる。
    Elastic Cloud Serverless は利用可能リージョンが限られており、
    GCP 東京（asia-northeast1）は未サポート。
    利用可能リージョンは API で確認:
      curl -H "Authorization: ApiKey <key>" https://api.elastic-cloud.com/api/v1/serverless/regions
    （例: gcp-asia-southeast1, gcp-us-central1, aws-ap-northeast-1）
  EOT
  type        = string
  default     = "gcp-asia-southeast1"
}

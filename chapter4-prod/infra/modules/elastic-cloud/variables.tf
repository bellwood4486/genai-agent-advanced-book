variable "region" {
  description = "GCP リージョン（例: asia-northeast1）。Elastic Cloud のリージョン ID に変換される（gcp- プレフィックス付与）。"
  type        = string
}

variable "project_name" {
  description = "Elasticsearch Serverless プロジェクト名"
  type        = string
  default     = "helpdesk-search"
}

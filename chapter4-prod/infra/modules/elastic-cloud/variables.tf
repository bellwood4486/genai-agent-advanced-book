variable "region" {
  description = "Elastic Cloud Serverless のリージョン ID（例: gcp-asia-southeast1）。API の region_id フィールドにそのまま渡される。"
  type        = string
}

variable "project_name" {
  description = "Elasticsearch Serverless プロジェクト名"
  type        = string
  default     = "helpdesk-search"
}

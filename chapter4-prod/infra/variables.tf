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

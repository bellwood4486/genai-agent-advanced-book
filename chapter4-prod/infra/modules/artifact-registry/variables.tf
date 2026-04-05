variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry リポジトリ名"
  type        = string
  default     = "helpdesk"
}

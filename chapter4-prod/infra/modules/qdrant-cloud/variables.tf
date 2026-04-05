variable "region" {
  description = "Qdrant Cloud クラスタを配置する GCP リージョン（例: asia-northeast1）"
  type        = string
}

variable "cluster_name" {
  description = "Qdrant Cloud クラスタ名"
  type        = string
  default     = "helpdesk-vectors"
}

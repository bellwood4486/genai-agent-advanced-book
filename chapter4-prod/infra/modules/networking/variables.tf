variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "vpc_name" {
  description = "VPC ネットワーク名"
  type        = string
  default     = "helpdesk-vpc"
}

variable "subnet_cidr" {
  description = <<-EOT
    サブネットの IP アドレス範囲（CIDR 表記）。
    Cloud Run Direct VPC Egress には /28 以上のサブネットが必要。
    学習用途のため最小サイズの /28（16 IP）で十分。
  EOT
  type        = string
  default     = "10.0.0.0/28"
}

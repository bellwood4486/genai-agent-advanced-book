output "network_id" {
  description = "VPC ネットワークの ID（他モジュールからの参照用）"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "VPC ネットワーク名"
  value       = google_compute_network.this.name
}

output "subnet_id" {
  description = "サブネットの ID（Cloud Run Direct VPC Egress で使用）"
  value       = google_compute_subnetwork.this.id
}

output "subnet_name" {
  description = "サブネット名"
  value       = google_compute_subnetwork.this.name
}

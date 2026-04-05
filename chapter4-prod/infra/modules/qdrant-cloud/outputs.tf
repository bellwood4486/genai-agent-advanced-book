output "endpoint" {
  description = "Qdrant Cloud クラスタのエンドポイント URL（例: https://xxx.gcp.cloud.qdrant.io:6333）"
  value       = qdrant-cloud_accounts_cluster.this.url
}

output "api_key" {
  description = "Qdrant Cloud データベース API キー。sensitive = true でログやプランに表示されない。"
  value       = qdrant-cloud_accounts_database_api_key_v2.this.key
  sensitive   = true
}

output "cluster_id" {
  description = "Qdrant Cloud クラスタ ID"
  value       = qdrant-cloud_accounts_cluster.this.id
}

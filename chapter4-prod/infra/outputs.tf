# Outputs は各 Increment の実装に合わせて追加していく。
# 将来追加予定:
#   cloud_run_url  — Increment 5
#   lb_url         — Increment 10

# Increment 3: Elastic Cloud Serverless
output "elasticsearch_endpoint" {
  description = "Elastic Cloud Serverless の Elasticsearch エンドポイント URL"
  value       = module.elastic-cloud.endpoint
}

output "kibana_endpoint" {
  description = "Elastic Cloud Serverless の Kibana エンドポイント URL"
  value       = module.elastic-cloud.kibana_endpoint
}

output "elasticsearch_cloud_id" {
  description = "Elastic Cloud ID（Elastic クライアントの初期化に使えるエンコード済み接続文字列）"
  value       = module.elastic-cloud.cloud_id
}

output "elasticsearch_credentials" {
  description = "Elasticsearch への Basic 認証情報（username + password）"
  value       = module.elastic-cloud.credentials
  sensitive   = true
}

# Increment 3: Qdrant Cloud
output "qdrant_endpoint" {
  description = "Qdrant Cloud クラスタのエンドポイント URL"
  value       = module.qdrant-cloud.endpoint
}

output "qdrant_api_key" {
  description = "Qdrant Cloud データベース API キー"
  value       = module.qdrant-cloud.api_key
  sensitive   = true
}

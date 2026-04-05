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

# Increment 4: GCP 基盤
output "artifact_registry_url" {
  description = "Artifact Registry Docker リポジトリの URL（docker push/pull 先）"
  value       = module.artifact-registry.repository_url
}

output "cloud_run_service_account_email" {
  description = "Cloud Run 用サービスアカウントのメールアドレス（Increment 5 で使用）"
  value       = google_service_account.cloud_run.email
}

output "github_actions_service_account_email" {
  description = "GitHub Actions CI/CD 用サービスアカウントのメールアドレス"
  value       = google_service_account.github_actions.email
}

output "vpc_network_name" {
  description = "VPC ネットワーク名（Increment 5 の Direct VPC Egress 設定で使用）"
  value       = module.networking.network_name
}

output "subnet_name" {
  description = "サブネット名（Increment 5 の Direct VPC Egress 設定で使用）"
  value       = module.networking.subnet_name
}

# Increment 5: Cloud Run
output "cloud_run_url" {
  description = "Cloud Run サービスの HTTPS URL（E2E テストの CLOUD_RUN_URL 環境変数に使用）"
  value       = module.cloud-run.service_url
}

# Increment 6: GCS + Cloud Run Jobs
output "gcs_bucket_name" {
  description = "ドキュメントアップロード用 GCS バケット名（make upload-docs で使用）"
  value       = module.storage.bucket_name
}

output "ingestion_job_name" {
  description = "インデックス作成 Cloud Run Job 名（make run-ingestion で使用）"
  value       = module.ingestion.job_name
}

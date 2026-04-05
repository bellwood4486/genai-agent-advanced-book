output "service_url" {
  description = "Cloud Run サービスの HTTPS URL（E2E テストや手動確認に使用）"
  value       = google_cloud_run_v2_service.this.uri
}

output "service_name" {
  description = "Cloud Run サービス名"
  value       = google_cloud_run_v2_service.this.name
}

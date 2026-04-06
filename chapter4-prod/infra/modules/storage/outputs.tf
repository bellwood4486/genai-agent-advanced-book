output "bucket_name" {
  description = "GCS バケット名（アプリの GCS_BUCKET_NAME 環境変数に使用）"
  value       = google_storage_bucket.documents.name
}

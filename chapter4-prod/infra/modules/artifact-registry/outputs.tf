output "repository_id" {
  description = "Artifact Registry リポジトリ ID"
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_url" {
  description = <<-EOT
    Artifact Registry リポジトリの Docker URL（docker push/pull のベース URL）。
    例: asia-northeast1-docker.pkg.dev/genai-book-ch4-helpdesk/helpdesk
  EOT
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}

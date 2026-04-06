output "job_name" {
  description = "Cloud Run Job 名（gcloud でジョブを手動実行する際に使用: gcloud run jobs execute <job_name>）"
  value       = google_cloud_run_v2_job.ingestion.name
}

output "secret_ids" {
  description = <<-EOT
    各シークレットの完全修飾 ID（projects/xxx/secrets/yyy 形式）のマップ。
    Cloud Run の secret_key_ref で参照する際に使用する（Increment 5）。
  EOT
  value = {
    for k, v in google_secret_manager_secret.this : k => v.id
  }
}

output "secret_names" {
  description = "各シークレットの名前（secret_id）のマップ"
  value = {
    for k, v in google_secret_manager_secret.this : k => v.secret_id
  }
}

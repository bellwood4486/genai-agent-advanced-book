output "endpoint" {
  description = "Elasticsearch エンドポイント URL（アプリからの API アクセス先）"
  value       = ec_elasticsearch_project.this.endpoints.elasticsearch
}

output "kibana_endpoint" {
  description = "Kibana エンドポイント URL（Web UI でインデックスを確認するのに使う）"
  value       = ec_elasticsearch_project.this.endpoints.kibana
}

output "cloud_id" {
  description = "Elastic Cloud ID（Elastic クライアントライブラリの初期化に使えるエンコード済み接続文字列）"
  value       = ec_elasticsearch_project.this.cloud_id
}

output "credentials" {
  description = "Elasticsearch への Basic 認証情報（username + password）。sensitive = true でログやプランに表示されない。"
  value = {
    username = ec_elasticsearch_project.this.credentials.username
    password = ec_elasticsearch_project.this.credentials.password
  }
  sensitive = true
}

output "project_id" {
  description = "Elastic Cloud プロジェクト ID"
  value       = ec_elasticsearch_project.this.id
}

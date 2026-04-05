# GCS バケット — ヘルプデスクエージェントが参照するドキュメントのアップロード先。
#
# Cloud Run Job（Increment 6）がこのバケットからファイルを読み取り、
# Elasticsearch / Qdrant のインデックスを作成する。
# 将来的に Eventarc トリガー（Increment 7）でアップロードを検知し、
# 自動的にインデックス作成ジョブを起動する。

resource "google_storage_bucket" "documents" {
  project  = var.project_id
  # GCS バケット名はグローバルで一意である必要があるため、project_id をプレフィックスに使う。
  name     = "${var.project_id}-helpdesk-docs"
  location = var.region

  # uniform_bucket_level_access: バケットレベルの IAM でアクセス制御を統一する。
  # オブジェクト単位の ACL を無効化し、IAM ポリシーだけで権限管理する（Google 推奨設定）。
  uniform_bucket_level_access = true

  # force_destroy: terraform destroy 時にバケット内のオブジェクトも自動削除する。
  # 学習用プロジェクトのため、クリーンアップを簡単にするために true にしている。
  # 本番環境では false にして誤削除を防ぐこと。
  force_destroy = true
}

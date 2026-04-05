# Docker コンテナイメージを保存する Artifact Registry リポジトリ。
#
# 旧 Container Registry (gcr.io) は非推奨のため、Artifact Registry を使用する。
# Docker イメージの push/pull 先:
#   <region>-docker.pkg.dev/<project_id>/<repository_id>/<image_name>:<tag>
# 例: asia-northeast1-docker.pkg.dev/genai-book-ch4-helpdesk/helpdesk/helpdesk-agent:latest
resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Helpdesk agent Docker images"

  # クリーンアップポリシー: 30日以上前の未タグイメージを自動削除する。
  # タグ付きイメージ（latest, git SHA 等）は削除されない。
  # CI で毎回ビルドすると大量の中間イメージが溜まるため、
  # このポリシーでストレージコストを自動的に抑える。
  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s" # 30日 = 30 * 24 * 60 * 60
    }
  }
}

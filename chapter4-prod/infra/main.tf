# Root module — enable each module block as the corresponding Increment is completed.

# --- Increment 4: GCP API 有効化 ---
# Cloud Run、Secret Manager、Artifact Registry の API を有効にする。
# 各モジュールが depends_on でこれらを参照することで、
# API が有効になる前にリソース作成が始まるのを防ぐ。
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"
  # プロジェクト削除時にこの API を無効化しない。
  # 無効化すると他のリソースに影響が出る可能性があるため false を推奨。
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# --- Increment 4: GitHub Actions CI/CD 用サービスアカウント ---
# GitHub Actions から GCP にアクセスするための専用 SA。
# terraform plan（Artifact Registry/Secret Manager/VPC 等の参照）と
# docker push（Artifact Registry への書き込み）に必要な権限を付与する。
# キーは Terraform で管理せず、gcloud CLI で別途生成して GitHub Secrets に登録する。
resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "github-actions-ci"
  display_name = "GitHub Actions CI/CD SA"
}

# terraform plan が GCP リソースの現状を読み取るために必要な読み取り権限。
# roles/viewer は compute, secretmanager, artifactregistry 等の
# 読み取り操作を網羅しており、terraform plan の refresh に使用される。
resource "google_project_iam_member" "github_actions_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# terraform init/plan が GCS backend（terraform state）を読み書きするために必要。
# state ファイルの読み取りと、plan 実行時のロック（書き込み）に使用される。
resource "google_project_iam_member" "github_actions_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# GitHub Actions の deploy ワークフロー（chapter4-prod-deploy.yml）が
# Artifact Registry に Docker イメージを push するために必要。
resource "google_project_iam_member" "github_actions_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# --- Increment 4: Cloud Run 用サービスアカウント ---
# デフォルトの Compute Engine SA ではなく専用 SA を作ることで、
# 最小権限の原則（Principle of Least Privilege）に従う。
# Increment 5 の cloud-run モジュールでこの SA を指定する。
resource "google_service_account" "cloud_run" {
  project      = var.project_id
  account_id   = "helpdesk-agent-runner"
  display_name = "Helpdesk Agent Cloud Run SA"
}

# Secret Manager のシークレットを読み取る権限。
# Cloud Run が Secret Manager からAPIキーを取得するために必要。
resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Artifact Registry からコンテナイメージを pull する権限。
# Cloud Run サービス起動時にイメージを取得するために必要。
resource "google_project_iam_member" "cloud_run_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Increment 3: Elastic Cloud Serverless + Qdrant Cloud
# APIキーはプロバイダレベル（providers.tf）で認証済みのため、モジュールへの受け渡しは不要。
module "elastic-cloud" {
  source = "./modules/elastic-cloud"
  # Elastic Cloud Serverless は利用可能リージョンが限られるため、
  # GCP の var.region とは別に elastic_region で独立して指定する。
  region = var.elastic_region
}

module "qdrant-cloud" {
  source = "./modules/qdrant-cloud"
  # Qdrant Cloud の Free Tier は提供リージョンが限られるため、
  # GCP の var.region とは別に qdrant_region で独立して指定する。
  region = var.qdrant_region
}

# Increment 4: GCP foundation
module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  region     = var.region

  # VPC/サブネットは Compute Engine API が必要。
  depends_on = [google_project_service.compute]
}

module "secret-manager" {
  source     = "./modules/secret-manager"
  project_id = var.project_id

  openai_api_key = var.openai_api_key
  # Elastic Cloud Serverless が自動生成した Elasticsearch 認証パスワードを
  # Secret Manager に保存する。Cloud Run からは secret_key_ref で参照する（Increment 5）。
  elastic_api_key = module.elastic-cloud.credentials.password
  # Qdrant Cloud が自動生成したデータベース API キーを Secret Manager に保存する。
  qdrant_api_key = module.qdrant-cloud.api_key

  depends_on = [google_project_service.secretmanager]
}

module "artifact-registry" {
  source     = "./modules/artifact-registry"
  project_id = var.project_id
  region     = var.region

  depends_on = [google_project_service.artifactregistry]
}

# Increment 5: Cloud Run MVP
# module "cloud-run" {
#   source            = "./modules/cloud-run"
#   project_id        = var.project_id
#   region            = var.region
#   elasticsearch_url = module.elastic-cloud.endpoint
#   qdrant_url        = module.qdrant-cloud.endpoint
# }

# Increment 6: GCS + Cloud Run Jobs
# module "storage" {
#   source     = "./modules/storage"
#   project_id = var.project_id
#   region     = var.region
# }

# module "ingestion" {
#   source     = "./modules/ingestion"
#   project_id = var.project_id
#   region     = var.region
# }

# Increment 8: Firestore
# module "firestore" {
#   source     = "./modules/firestore"
#   project_id = var.project_id
# }

# Increment 9: Observability
# module "observability" {
#   source     = "./modules/observability"
#   project_id = var.project_id
# }

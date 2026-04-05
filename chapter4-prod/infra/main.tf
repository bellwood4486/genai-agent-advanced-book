# Root module — enable each module block as the corresponding Increment is completed.

# Increment 3: Elastic Cloud Serverless + Qdrant Cloud
# APIキーはプロバイダレベル（providers.tf）で認証済みのため、モジュールへの受け渡しは不要。
module "elastic-cloud" {
  source = "./modules/elastic-cloud"
  region = var.region
}

module "qdrant-cloud" {
  source = "./modules/qdrant-cloud"
  region = var.region
}

# Increment 4: GCP foundation
# module "networking" {
#   source     = "./modules/networking"
#   project_id = var.project_id
#   region     = var.region
# }

# module "secret-manager" {
#   source         = "./modules/secret-manager"
#   project_id     = var.project_id
#   openai_api_key = var.openai_api_key
# }

# module "artifact-registry" {
#   source     = "./modules/artifact-registry"
#   project_id = var.project_id
#   region     = var.region
# }

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

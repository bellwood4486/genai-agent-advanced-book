# Root module — enable each module block as the corresponding Increment is completed.

# Increment 3: Elastic Cloud Serverless + Qdrant Cloud
# module "elastic-cloud" {
#   source         = "./modules/elastic-cloud"
#   elastic_api_key = var.elastic_api_key
#   region         = var.region
# }

# module "qdrant-cloud" {
#   source               = "./modules/qdrant-cloud"
#   qdrant_cloud_api_key = var.qdrant_cloud_api_key
# }

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

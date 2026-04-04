terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    ec = {
      source  = "elastic/ec"
      version = "~> 0.10"
    }
    qdrant = {
      source  = "qdrant/qdrant-cloud"
      version = "~> 1.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "ec" {
  apikey = var.elastic_api_key
}

provider "qdrant" {
  api_key = var.qdrant_cloud_api_key
}

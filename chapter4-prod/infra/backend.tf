# Replace <your-tf-state-bucket> with the actual GCS bucket name created in Step 0.
# Run: gcloud storage buckets create gs://<your-tf-state-bucket> --location=asia-northeast1 --uniform-bucket-level-access
# Then enable versioning: gcloud storage buckets update gs://<your-tf-state-bucket> --versioning
#
# For terraform validate in Increment 1 (before the bucket exists), use:
#   terraform init -backend=false

terraform {
  backend "gcs" {
    bucket = "<your-tf-state-bucket>"
    prefix = "chapter4-prod/terraform/state"
  }
}

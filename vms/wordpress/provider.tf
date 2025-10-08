terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Include all modules/resources by sourcing other .tf files
# No resource definitions here—keeps main.tf as the entry point

# Optionally, you may add remote state, backend, or provider blocks here if needed.

# Example backend configuration (uncomment if using remote state):
# terraform {
#   backend "gcs" {
#     bucket  = "my-tf-state-bucket"
#     prefix  = "prod/state"
#   }
# }
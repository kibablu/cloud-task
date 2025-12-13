# --- Terraform Backend (Highly Recommended for State Management) ---
# Replace YOUR_BUCKET_NAME with a real GCS bucket name you've created.
terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket = "terra-dev-chris"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.13.0, < 7.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Get current Google Cloud auth token
data "google_client_config" "current" {}

# Enable necessary Google Cloud APIs
resource "google_project_service" "gcp_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "certificatemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "dns.googleapis.com",
  ])
  service            = each.key
  project            = var.project_id
  disable_on_destroy = false
}

# ------------------------------------------------
# Kubernetes & Helm Provider Configuration
# ------------------------------------------------

# Data source to fetch authentication details for the ArgoCD GKE cluster
data "google_container_cluster" "chris_gke_private_auth" {
  name     = google_container_cluster.chris_gke_cluster.name
  location = google_container_cluster.chris_gke_cluster.location
  project  = var.project_id
  depends_on = [
  google_container_cluster.chris_gke_cluster]
}

# Kubernetes provider configured to connect to the ArgoCD cluster
provider "kubernetes" {
  alias                  = "chris_gke"
  host                   = "https://${data.google_container_cluster.chris_gke_private_auth.private_cluster_config[0].public_endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.chris_gke_private_auth.master_auth[0].cluster_ca_certificate)
}

# Helm provider configured to use the ArgoCD Kubernetes provider
provider "helm" {
  alias = "chris_gke"
  kubernetes = {
    host                   = "https://${data.google_container_cluster.chris_gke_private_auth.endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.chris_gke_private_auth.master_auth[0].cluster_ca_certificate)
  }
}
  
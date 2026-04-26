# Root Module

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # GCS bucket for remote state
  backend "gcs" {
    bucket = "YOUR_BUCKET_NAME"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Storage (GCS bucket for static site) 
module "storage" {
  source = "./modules/storage"

  project_id  = var.project_id
  region      = var.region
  bucket_name = var.bucket_name
  labels      = var.labels
}

# Load Balancer + CDN 
module "load_balancer" {
  source = "./modules/load_balancer"

  project_id       = var.project_id
  region           = var.region
  name_prefix      = var.name_prefix
  bucket_name      = module.storage.bucket_name
  bucket_self_link = module.storage.bucket_self_link
  enable_cdn       = true
  ssl_domains      = [var.domain]
  function_name    = module.cloud_function.function_name
  labels           = var.labels

  depends_on = [module.storage]
}

# DNS
module "dns" {
  source = "./modules/dns"

  project_id       = var.project_id
  domain           = var.domain
  dns_zone_name    = var.dns_zone_name
  lb_ip_address    = module.load_balancer.lb_ip_address
  create_zone      = var.create_dns_zone
  create_www_cname = true

  depends_on = [module.load_balancer]
}

# Firestore (visitor counter database)
module "firestore" {
  source = "./modules/firestore"

  project_id      = var.project_id
  location_id     = var.firestore_location
  collection_name = var.counter_collection
}

# Cloud Function (visitor counter API) 
module "cloud_function" {
  source = "./modules/cloud_function"

  project_id      = var.project_id
  region          = var.region
  name_prefix     = var.name_prefix
  collection_name = var.counter_collection
  document_id     = "counter"
  allowed_origin  = "https://${var.domain}"
  labels          = var.labels

  depends_on = [module.firestore]
}

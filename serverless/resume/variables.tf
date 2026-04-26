# Root Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "Globally unique name for the GCS bucket hosting the resume"
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to all named GCP resources (load balancer, forwarding rules, etc.)"
  type        = string
  default     = "cloud-resume"
}

variable "domain" {
  description = "Apex domain for the resume, e.g. resume.example.com"
  type        = string
}

variable "dns_zone_name" {
  description = "Name of the Cloud DNS managed zone (must already exist OR set create_zone = true in dns module)"
  type        = string
}

variable "create_dns_zone" {
  description = "Set true to create the Cloud DNS managed zone via Terraform. Set false if the zone already exists."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to every resource"
  type        = map(string)
  default = {
    project     = "cloud-resume"
    managed_by  = "terraform"
  }
}

#  Firestore 
variable "firestore_location" {
  description = "Firestore multi-region location: nam5 (US) or eur3 (EU)"
  type        = string
  default     = "nam5"
}

variable "counter_collection" {
  description = "Firestore collection name for the visitor counter"
  type        = string
  default     = "visitors"
}

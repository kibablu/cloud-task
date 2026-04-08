variable "project_id" {
  description = "The GCP project ID to deploy resources into"
  type        = string
  default     = "PROJECT_ID"
}

variable "region" {
  description = "The GCP region to deploy resources (e.g., us-central1)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for the single VM (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

# Domain Variables
variable "domain_name" {
  description = "The public domain name for your Cloud DNS zone"
  type        = string
  default     = "example.org"
}

variable "iap_client_id" {
  description = "OAuth2 Client ID for IAP"
}

variable "iap_client_secret" {
  description = "OAuth2 Client Secret for IAP"
  sensitive   = true
}
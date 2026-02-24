## Project and Location Variables
variable "project_id" {
  description = "The GCP project ID to deploy resources into"
  type        = string
  default     = "project_id"
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

## Domain Variables
variable "domain_name" {
  description = "The public domain name for your Cloud DNS zone (e.g., chrisproject.org)"
  type        = string
  default     = "example.com"
}

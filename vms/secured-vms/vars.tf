# Define variables for project ID and region
variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "PROJECT_ID" # Change this to your GCP project ID
}

variable "gcp_region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1" # Change this to your desired region
}

variable "gcp_zone" {
  description = "The GCP zone to deploy resources"
  type        = string
  default     = "us-central1-a" # Change this to your desired zone within the region
}

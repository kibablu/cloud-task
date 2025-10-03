variable "project_id" {
  description = "The GCP project ID where resources will be deployed."
  type        = string
  default     = "project_id"
}

variable "region" {
  description = "The region to deploy resources (e.g., us-central1)."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy the Compute Engine instance (e.g., us-central1-a)."
  type        = string
  default     = "us-central1-a"
}
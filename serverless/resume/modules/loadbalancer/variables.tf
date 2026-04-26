# Module: load_balancer — Variables

variable "project_id" {
  type = string
}

variable "name_prefix" {
  type    = string
  default = "cloud-resume"
}

variable "bucket_name" {
  description = "Name of the GCS bucket used as the backend"
  type        = string
}

variable "bucket_self_link" {
  description = "Self-link of the GCS bucket (unused directly but makes dependency explicit)"
  type        = string
}

variable "enable_cdn" {
  description = "Enable Cloud CDN on the backend bucket"
  type        = bool
  default     = true
}

variable "ssl_domains" {
  description = "List of domains for the Google-managed SSL certificate. Populated by root module from var.domain."
  type        = list(string)
  default     = []
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "function_name" {
  description = "Cloud Function (Cloud Run) service name to route /api/counter to"
  type        = string
}

variable "region" {
  description = "Region where the Cloud Function is deployed (for the serverless NEG)"
  type        = string
}
variable "project_id" { type = string }

variable "region" {
  description = "Region for the Cloud Function (Gen 2 is regional)"
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  type    = string
  default = "cloud-resume"
}

variable "collection_name" {
  description = "Firestore collection name"
  type        = string
  default     = "visitors"
}

variable "document_id" {
  description = "Firestore document ID for the counter"
  type        = string
  default     = "counter"
}

variable "allowed_origin" {
  description = "Value for Access-Control-Allow-Origin header. Set to your resume domain in production."
  type        = string
  default     = "*"
}

variable "labels" {
  type    = map(string)
  default = {}
}

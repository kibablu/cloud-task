variable "project_id" {
  type = string
}

variable "location_id" {
  description = "Firestore location, e.g. nam5 (US multi-region) or eur3 (EU multi-region)"
  type        = string
  default     = "nam5"
}

variable "collection_name" {
  description = "Firestore collection that holds the visitor counter document"
  type        = string
  default     = "visitors"
}

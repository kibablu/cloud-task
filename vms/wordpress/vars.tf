variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "your_project_id"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "your_region"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "your_zone"
}

variable "subnet_cidr" {
  description = "CIDR range for the main subnet"
  type        = string
  default     = "10.10.0.0/27"
}

variable "custom_image" {
  description = "Custom image name for MIG instances"
  type        = string
  default = "wordpress-custom-image-final" # custom image you created earlier 
}

variable "custom_image_project" {
  description = "Project ID where the custom image is stored"
  type        = string
  default = "your_project_id"
}

variable "bucket_name" {
  description = "Cloud Storage bucket name"
  type        = string
}

# for sensitive data terraform will read from terraform.tvars file
variable "wordpress_db_user" {
  description = "WordPress DB username to store in Secret Manager"
  type        = string
  sensitive   = true
}

variable "wordpress_db_password" {
  description = "WordPress DB password to store in Secret Manager"
  type        = string
  sensitive   = true
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "main-sql"
}

variable "wp_domain" {
  description = "Root domain for WordPress (e.g. example.com)"
  type        = string
  default     = "example.com"
}

variable "wp_www_domain" {
  description = "WWW subdomain for WordPress (e.g. www.example.com)"
  type        = string
  default     = "www.example.com"
}
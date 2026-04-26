# Module: dns — Variables

variable "project_id" {
  type = string
}

variable "domain" {
  description = "Fully-qualified domain name, e.g. resume.example.com"
  type        = string
}

variable "dns_zone_name" {
  description = "Cloud DNS managed zone name"
  type        = string
}

variable "lb_ip_address" {
  description = "Load balancer global static IP to use in the A record"
  type        = string
}

variable "create_zone" {
  description = "Set true to create the Cloud DNS zone inside this module. Set false (default) to use an existing zone."
  type        = bool
  default     = true
}

variable "create_www_cname" {
  description = "Create a www CNAME pointing to the apex domain"
  type        = bool
  default     = true
}

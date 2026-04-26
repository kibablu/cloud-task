###############################################################
# Module: dns
#
# Options:
#   A) Use an existing Cloud DNS managed zone (default)
#   B) Create a new managed zone (set create_zone = true)
#
# Creates an A record pointing var.domain → lb_ip_address.
# If var.domain is an apex (no subdomain), also creates a www CNAME.
###############################################################

locals {
  # Ensure the DNS name always ends with a trailing dot (RFC 1035)
  dns_name = endswith(var.domain, ".") ? var.domain : "${var.domain}."
}

# Optional: create the managed zone
resource "google_dns_managed_zone" "resume" {
  count       = var.create_zone ? 1 : 0
  name        = var.dns_zone_name
  project     = var.project_id
  dns_name    = local.dns_name
  description = "Cloud Resume managed DNS zone"
  visibility  = "public"
}

# Data source: look up existing zone (when create_zone = false) 
data "google_dns_managed_zone" "existing" {
  count   = var.create_zone ? 0 : 1
  name    = var.dns_zone_name
  project = var.project_id
}

locals {
  zone_name = var.create_zone ? google_dns_managed_zone.resume[0].name : data.google_dns_managed_zone.existing[0].name
}

# A record: domain → LB static IP
resource "google_dns_record_set" "resume_a" {
  name         = local.dns_name
  project      = var.project_id
  managed_zone = local.zone_name
  type         = "A"
  ttl          = 300

  rrdatas = [var.lb_ip_address]
}

# Optional www CNAME 
# Only created when var.domain does NOT already start with "www."
resource "google_dns_record_set" "www_cname" {
  count        = var.create_www_cname && !startswith(var.domain, "www.") ? 1 : 0
  name         = "www.${local.dns_name}"
  project      = var.project_id
  managed_zone = local.zone_name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [local.dns_name]
}

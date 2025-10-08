# Create a Cloud DNS managed zone for your domain
resource "google_dns_managed_zone" "main" {
  name     = "exmaple-name" # change for your domain
  dns_name = "${var.wp_domain}."
  description = "Managed zone for example domain"
}

# Create an A record for the root domain, pointing to the load balancer IP
resource "google_dns_record_set" "a_record" {
  name         = "${var.wp_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.main.name
  rrdatas      = [google_compute_global_address.lb_ip.address]
}

# Create a CNAME record for the www subdomain, pointing to the root domain
resource "google_dns_record_set" "cname_record" {
  name         = "${var.wp_www_domain}."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.main.name
  rrdatas      = ["${var.wp_domain}."]
}
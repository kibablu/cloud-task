# --- Cloud DNS Public Managed Zone ---
resource "google_dns_managed_zone" "chris_dns_zone" {
  name        = "chris-public-zone"
  dns_name    = "${var.domain_name}." # use your domain "example.com."
  description = "Public DNS zone for Chris project GKE ingress"
  visibility  = "public"
}

# Create an A record for the root domain pointing to the Ingress IP
resource "google_dns_record_set" "root_a_record" {
  name         = google_dns_managed_zone.chris_dns_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.chris_dns_zone.name
  rrdatas      = [google_compute_global_address.ingress_static_ip.address]
}

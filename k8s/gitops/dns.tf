# --- Cloud DNS Public Managed Zone ---
resource "google_dns_managed_zone" "chris_dns_zone" {
  name        = "chris-public-zone"
  dns_name    = "${var.domain_name}." # This will use "klaudmazoezi.top."
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

# Create a CNAME record for ArgoCD to point to the root domain
resource "google_dns_record_set" "argocd_cname_record" {
  name         = "argocd.${google_dns_managed_zone.chris_dns_zone.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.chris_dns_zone.name
  rrdatas      = [google_dns_managed_zone.chris_dns_zone.dns_name]
}

# Create a CNAME record for Grafana to point to the root domain
resource "google_dns_record_set" "grafana_cname_record" {
  name         = "grafana.${google_dns_managed_zone.chris_dns_zone.dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.chris_dns_zone.name
  rrdatas      = [google_dns_managed_zone.chris_dns_zone.dns_name]
}

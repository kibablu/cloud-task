resource "google_dns_managed_zone" "n8n_zone" {
  name        = "n8n-managed-zone"
  dns_name    = "${var.domain_name}."
  description = "Managed zone for n8n and automation services"
  
  visibility = "public"
}

resource "google_dns_record_set" "n8n_dns" {
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.n8n_zone.name
  rrdatas      = [google_compute_global_address.n8n_ip.address] 
  # Ensure the IP exists before trying to map it to DNS
  depends_on = [google_compute_global_address.n8n_ip]
}


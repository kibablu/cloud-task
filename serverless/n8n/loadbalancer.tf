resource "google_compute_global_address" "n8n_ip" {
  name = "n8n-static-ip"
  depends_on = [data.google_project.project]
}

# Create the Serverless NEG (The bridge between LB and Cloud Run)
resource "google_compute_region_network_endpoint_group" "n8n_neg" {
  name                  = "n8n-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_run {
    service = google_cloud_run_v2_service.n8n.name
  }
}

resource "google_compute_backend_service" "n8n_backend" {
  name                  = "n8n-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  
  backend {
    group = google_compute_region_network_endpoint_group.n8n_neg.id
  }

  iap {
    enabled              = true 
    oauth2_client_id     = var.iap_client_id
    oauth2_client_secret = var.iap_client_secret
  }
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "n8n_cert" {
  name = "n8n-ssl-cert"
  managed {
    domains = [var.domain_name]
  }
}

# URL Map (Routing)
resource "google_compute_url_map" "n8n_url_map" {
  name            = "n8n-url-map"
  default_service = google_compute_backend_service.n8n_backend.id
}

# Target HTTPS Proxy
resource "google_compute_target_https_proxy" "n8n_https_proxy" {
  name             = "n8n-https-proxy"
  url_map          = google_compute_url_map.n8n_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.n8n_cert.id]
}

# Global Forwarding Rule (The Entry Point)
resource "google_compute_global_forwarding_rule" "n8n_forwarding_rule" {
  name                  = "n8n-forwarding-rule"
  target                = google_compute_target_https_proxy.n8n_https_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.n8n_ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Reserve a global static IP address for the load balancer frontend
resource "google_compute_global_address" "lb_ip" {
  name = "lb-ip"
}

# Create a backend service pointing to the MIG
resource "google_compute_backend_service" "default" {
  name                  = "lb-backend-service"
  protocol              = "HTTPS"
  port_name             = "https"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.default.id]
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_instance_group_manager.mig.instance_group
  }

  enable_cdn = false

  depends_on = [
    google_compute_health_check.default
  ]
  timeouts {
    create = "30m" # prevents for terraform to through error due to health check not ready
  }
}

# Define URL map to route all traffic to the backend service
resource "google_compute_url_map" "default" {
  name            = "lb-url-map"
  default_service = google_compute_backend_service.default.id
}

# Create the target HTTPS proxy using your managed SSL certificate
resource "google_compute_target_https_proxy" "default" {
  name             = "lb-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.main.id]
}

# Create a global forwarding rule to route requests to the HTTPS proxy
resource "google_compute_global_forwarding_rule" "https" {
  name                  = "lb-https-forwarding-rule"
  target                = google_compute_target_https_proxy.default.id
  port_range            = "443"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb_ip.address
}

# OUTPUT: Static IP address to use in DNS
output "lb_static_ip" {
  description = "The static IP address of the HTTPS load balancer"
  value       = google_compute_global_address.lb_ip.address
}
# Module: load_balancer
#
# Creates:
#   1. Global static external IP
#   2. Backend bucket (GCS) + Cloud CDN — EXTERNAL_MANAGED scheme
#   3. Serverless NEG + backend service for Cloud Function API
#   4. URL map — /api/counter → Function, /* → GCS bucket
#   5. Google-managed SSL certificate
#   6. HTTPS target proxy + forwarding rule (port 443)
#   7. HTTP → HTTPS redirect (port 80)
#
# All resources use load_balancing_scheme = EXTERNAL_MANAGED
# (modern Application Load Balancer). Mixing EXTERNAL and
# EXTERNAL_MANAGED in the same URL map is not allowed by GCP.


# 1. Global Static IP 
resource "google_compute_global_address" "lb_ip" {
  name        = "${var.name_prefix}-ip"
  project     = var.project_id
  description = "Static IP for the Cloud Resume load balancer"
}

# 2. Backend Bucket (static site) + Cloud CDN
# Backend buckets are scheme-agnostic — they work with both
# EXTERNAL and EXTERNAL_MANAGED forwarding rules.
resource "google_compute_backend_bucket" "resume" {
  name        = "${var.name_prefix}-backend"
  project     = var.project_id
  bucket_name = var.bucket_name
  enable_cdn  = var.enable_cdn

  cdn_policy {
    cache_mode       = "CACHE_ALL_STATIC"
    client_ttl       = 3600
    default_ttl      = 86400
    max_ttl          = 604800
    negative_caching = true

    negative_caching_policy {
      code = 404
      ttl  = 60
    }
  }
}

# 3. Serverless NEG + Backend Service → Cloud Function
resource "google_compute_region_network_endpoint_group" "function_neg" {
  name                  = "${var.name_prefix}-fn-neg"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.function_name
  }
}

resource "google_compute_backend_service" "function" {
  name    = "${var.name_prefix}-fn-backend"
  project = var.project_id

  # Must match the forwarding rule scheme.
  # Serverless NEGs do not support protocol or port_name.
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false

  backend {
    group = google_compute_region_network_endpoint_group.function_neg.id
  }
}

# 4. URL Map
resource "google_compute_url_map" "resume" {
  name            = "${var.name_prefix}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_bucket.resume.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "paths"
  }

  path_matcher {
    name            = "paths"
    default_service = google_compute_backend_bucket.resume.self_link

    path_rule {
      paths   = ["/api/counter", "/api/counter/*"]
      service = google_compute_backend_service.function.self_link
    }
  }
}

# HTTP → HTTPS redirect map
resource "google_compute_url_map" "http_redirect" {
  name    = "${var.name_prefix}-http-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# 5. Google-Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "resume" {
  name    = "${var.name_prefix}-cert"
  project = var.project_id

  managed {
    domains = var.ssl_domains
  }

  lifecycle {
    create_before_destroy = true
  }
}

#  6. HTTPS Target Proxy + Forwarding Rule 
resource "google_compute_target_https_proxy" "resume" {
  name             = "${var.name_prefix}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.resume.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.resume.self_link]
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name_prefix}-https-fwd"
  project               = var.project_id
  target                = google_compute_target_https_proxy.resume.self_link
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  labels                = var.labels
}

# 7. HTTP → HTTPS Redirect
resource "google_compute_target_http_proxy" "redirect" {
  name    = "${var.name_prefix}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name_prefix}-http-fwd"
  project               = var.project_id
  target                = google_compute_target_http_proxy.redirect.self_link
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  labels                = var.labels
}



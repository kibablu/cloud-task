resource "google_compute_managed_ssl_certificate" "main" {
  name = "wp-managed-ssl"
  managed {
    domains = [
      var.wp_domain,
      var.wp_www_domain
    ]
  }
}
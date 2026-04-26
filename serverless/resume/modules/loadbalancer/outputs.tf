# Module: load_balancer — Outputs

output "lb_ip_address" {
  description = "Global static IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "lb_ip_name" {
  description = "Resource name of the reserved global IP"
  value       = google_compute_global_address.lb_ip.name
}

output "backend_bucket_self_link" {
  description = "Self-link of the backend bucket resource"
  value       = google_compute_backend_bucket.resume.self_link
}

output "ssl_certificate_name" {
  description = "Name of the Google-managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.resume.name
}

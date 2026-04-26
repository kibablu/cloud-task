# Root Outputs

output "bucket_name" {
  description = "GCS bucket hosting the static site"
  value       = module.storage.bucket_name
}

output "bucket_url" {
  description = "GCS bucket self-link"
  value       = module.storage.bucket_self_link
}

output "lb_ip_address" {
  description = "Global static IP assigned to the load balancer"
  value       = module.load_balancer.lb_ip_address
}

output "lb_ip_name" {
  description = "Name of the reserved global static IP"
  value       = module.load_balancer.lb_ip_name
}

output "resume_url" {
  description = "Public URL of the resume (via load balancer IP)"
  value       = "https://${module.load_balancer.lb_ip_address}"
}

output "resume_domain_url" {
  description = "Public URL via custom domain (DNS propagation may take a few minutes)"
  value       = "https://${var.domain}"
}

output "dns_zone_name_servers" {
  description = "Name servers for the Cloud DNS zone (update your registrar if zone was created here)"
  value       = module.dns.name_servers
}

output "function_url" {
  description = "Visitor counter API endpoint (call this from your resume JS)"
  value       = module.cloud_function.function_url
}

output "function_name" {
  description = "Cloud Function resource name"
  value       = module.cloud_function.function_name
}

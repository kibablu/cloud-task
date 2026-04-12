output "n8n_url" {
  value       = "https://${var.domain_name}"
  description = "The primary custom URL for n8n instance."
}

output "cloud_run_original_url" {
  value       = google_cloud_run_v2_service.n8n.uri
  description = "The default Google-provided URL for Cloud Run (IAP will still protect this)."
}

# --- DNS Configuration ---
# Copy these 4 servers to your Domain Registrar (GoDaddy, Namecheap, etc.)

output "dns_name_servers" {
  value       = google_dns_managed_zone.n8n_zone.name_servers
  description = "Update your domain registrar's NS records with these Google Cloud DNS servers."
}

output "vpc_connector_id" {
  value       = google_vpc_access_connector.connector.id
  description = "The bridge connecting Cloud Run to your private VM."
}

# --- Database Details (Internal Connectivity) ---

output "database_connection_name" {
  value       = google_sql_database_instance.n8n_db.connection_name
  description = "The Cloud SQL connection string used by Cloud Run."
}

output "database_user" {
  value       = google_sql_user.users.name
  description = "The database username for n8n."
}

# --- Security & IAP ---

output "iap_status" {
  value       = "IAP is enabled for ${var.domain_name}. Only authorized Google accounts can access."
  description = "Confirmation of the Zero-Trust security layer."
}

# --- DeepSeek / Ollama VM (Private Access) ---

output "vm_internal_ip" {
  value       = google_compute_instance.soccer_vm.network_interface[0].network_ip
  description = "The private IP of the Ollama VM."
}

output "vm_ssh_command" {
  value       = "gcloud compute ssh ${google_compute_instance.soccer_vm.name} --tunnel-through-iap --project ${var.project_id} --zone ${google_compute_instance.soccer_vm.zone}"
  description = "Run this command to SSH into your private VM via IAP tunnel."
}

# --- Soccer MCP (Internal Only) ---

output "soccer_mcp_internal_url" {
  value       = google_cloud_run_v2_service.soccer_mcp.uri
  description = "USE THIS in n8n MCP Tool. Note: Only reachable via VPC Connector."
}

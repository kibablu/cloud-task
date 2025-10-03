# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "wordpress_vm_public_ip" {
  description = "The public IP address of the WordPress VM. Access this URL to complete the WordPress setup."
  value       = google_compute_instance.wordpress_vm.network_interface[0].access_config[0].nat_ip
}

output "cloud_sql_instance_connection_name" {
  description = "The connection name for the highly available Cloud SQL instance (used by the Cloud SQL Proxy)."
  value       = google_sql_database_instance.wordpress_db.connection_name
}

output "db_secret_id" {
  description = "The ID of the Secret Manager secret holding the database password."
  value       = google_secret_manager_secret.wordpress_db_creds.secret_id
}

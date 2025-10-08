# Private Service Access for Cloud SQL (enables private IP for SQL)
resource "google_compute_global_address" "private_service_access" {
  name          = "private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}

# Cloud SQL instance (MySQL, sandbox tier, HA, private IP only)
resource "google_sql_database_instance" "main" {
  name             = var.sql_instance_name
  region           = var.region
  database_version = "MYSQL_8_0"

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL" # For HA
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }
    
  }

  deletion_protection = false

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

# Create a default database for WordPress
resource "google_sql_database" "wordpress" {
  name     = "wordpress"
  instance = google_sql_database_instance.main.name
}

# References the actual secret version resources from secrets.tf
resource "google_sql_user" "wordpress" {
  # Assuming your secrets.tf resources are named 'db_user_version' and 'db_password_version'
  name     = google_secret_manager_secret_version.db_user_version.secret_data
  instance = google_sql_database_instance.main.name
  password = google_secret_manager_secret_version.db_password_version.secret_data
}

# Output Cloud SQL connection name for use in instance template metadata
output "cloudsql_connection_name" {
  value       = google_sql_database_instance.main.connection_name
  description = "Cloud SQL instance connection name, used by Cloud SQL Proxy"
}
# Generate a random password for the database
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Cloud SQL Instance
resource "google_sql_database_instance" "n8n_db" {
  name             = "n8n-persistence-instance"
  database_version = "POSTGRES_15"
  region           = var.region
  settings {
    tier = "db-custom-2-7680" 
    edition = "ENTERPRISE"

    disk_type            = "PD_SSD"
    disk_size            = 20
    disk_autoresize      = true
    disk_autoresize_limit = 50 

    # Database Flags to handle connection exhaustion
    database_flags {
      name  = "max_connections"
      value = "300"
    }

    database_flags {
      name  = "idle_in_transaction_session_timeout"
      value = "60000" # 1 minute - kills "hanging" transactions
    }
    
    backup_configuration {
      enabled = false # Set to true for production!
    }

    ip_configuration {
      ipv4_enabled                                  = true # Change to false if using strictly Private IP
      enable_private_path_for_google_cloud_services = false # Set to true for production!
    }
  }
  
  deletion_protection = false # Set to true for production!
}

resource "google_sql_database" "database" {
  name     = "n8n"
  instance = google_sql_database_instance.n8n_db.name
}

resource "google_sql_user" "users" {
  name     = "n8n_user"
  instance = google_sql_database_instance.n8n_db.name
  password = random_password.db_password.result
}
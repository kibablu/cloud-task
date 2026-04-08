resource "google_cloud_run_v2_service" "n8n" {
  name     = "n8n-automation"
  location = "us-central1"
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  
  launch_stage = "BETA"
  provider     = google-beta

  template {
    timeout = "600s"
    service_account = google_service_account.cloud_run_sa.email
    session_affinity = true

    # n8n and MCP need to talk over private IP
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC" 
    }
    scaling {
      max_instance_count = 5
      min_instance_count = 1
    }

   containers {
      image = "us-central1-docker.pkg.dev/${var.project_id}/soccermcp/n8n-custom:latest"
      ports { 
        container_port = 5678 
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi" 
        }
        cpu_idle = false # Keep CPU always on to maintain DB connection pools
      }
      # Tell Cloud Run to wait specifically for the app to be "ready"
      startup_probe {
        http_get {
          path = "/health" # Match the N8N_ENDPOINT_HEALTH value
          port = 5678
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 30 
      }

      # Liveness Probe - Restarts container if DB connection dies
      liveness_probe {
        http_get {
          path = "/health"
          port = 5678
        }
        initial_delay_seconds = 60
        period_seconds        = 20
      }

      env {
        name  = "N8N_COMMUNITY_PACKAGES_ENABLED"
        value = "true"
      }
      env {
        name  = "NODE_FUNCTION_ALLOW_EXTERNAL"
        value = "n8n-nodes-credentials-google-identity-token"
      }
      env {
        name  = "N8N_PORT"
        value = "5678"
      }
      env {
        name  = "N8N_ENDPOINT_HEALTH"
        value = "health" 
      }
      # n8n Database Configuration
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = google_sql_database.database.name
      }
      env {
        name  = "DB_POSTGRESDB_HOST"
        value = "/cloudsql/${google_sql_database_instance.n8n_db.connection_name}"
      }
      env {
        name  = "DB_POSTGRESDB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_POSTGRESDB_USER"
        value = google_sql_user.users.name
      }
      env {
        name  = "DB_POSTGRESDB_PASSWORD"
        value = random_password.db_password.result
      }

      env {
        name  = "DB_POSTGRESDB_POOL_MAX"
        value = "15" # Caps each Cloud Run instance to 15 connections
      }
      
      # IAP & Domain Configuration
      env {
        name  = "N8N_SECURE_COOKIE"
        value = "true"
      }
      env {
        name  = "N8N_EDITOR_BASE_URL"
        value = "https://${var.domain_name}/"
      }
      # Required for n8n to trust the Load Balancer's headers
      env {
        name  = "N8N_PROXY_HOPS"
        value = "1"
      }
      # Ensure n8n doesn't try to use a sub-path
      env {
        name  = "N8N_PATH"
        value = "/"
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # Mount the Cloud SQL Instance
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.n8n_db.connection_name]
      }
    }
  }
}

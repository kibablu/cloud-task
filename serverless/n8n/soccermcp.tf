resource "google_cloud_run_v2_service" "soccer_mcp" {
  name                = "soccerdata-mcp"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    timeout          = "3600s"
    session_affinity = true 

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/soccermcp/soccer-server:latest"
      
      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1024Mi"
        }
        cpu_idle = false 
      }
    }
    
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
  }
}
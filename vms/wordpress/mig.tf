# Use locals and templatefile() instead of the deprecated data "template_file"
locals {
  startup_script = templatefile("${path.module}/scripts/cloud_sql_proxy_install.sh", {
    # Pass the connection name as a template variable
    connection_name = google_sql_database_instance.main.connection_name
    wp_domain       = var.wp_domain
    wp_www_domain   = var.wp_www_domain
  })
}

resource "google_compute_instance_template" "mig_template" {
  name           = "mig-template"
  machine_type   = "e2-medium"
  can_ip_forward = false

  service_account {
    email  = google_service_account.mig_sa.email
    scopes = ["cloud-platform"]
  }

  disk {
    source_image = "projects/${var.custom_image_project}/global/images/${var.custom_image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
    # No access_config, so NO PUBLIC IP
  }

    metadata = {
      # Reference the local variable
    startup-script               = local.startup_script
    }
  tags = ["mig"]
}

# Health Check for MIG (used by LB and autohealing)
resource "google_compute_health_check" "default" {
  name               = "mig-hc"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  https_health_check {
    port         = 443
    request_path = "/health.txt" # path for health check to ping
  }
}

# Managed Instance Group (regional)
resource "google_compute_region_instance_group_manager" "mig" {
  name                = "mig"
  region              = var.region
  base_instance_name  = "mig"
  version {
    instance_template = google_compute_instance_template.mig_template.id
    name              = "primary"
  }
  target_size         = 3

  named_port {
    name = "https"
    port = 443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
}
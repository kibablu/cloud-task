# Allow MIG to connect to Cloud SQL (port 3306) within the VPC
resource "google_compute_firewall" "allow_mig_sql" {
  name    = "allow-mig-sql"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  # Restrict source to the subnet or tag your MIG
  source_tags = ["mig"]
  target_tags = ["cloudsql"]
  description = "Allow MIG instances to connect to Cloud SQL on port 3306"
}

# Allow SSH from Google IAP only (for management)
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "allow-ssh-iap"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP IP range
  target_tags   = ["mig"]
  description   = "Allow SSH access to MIG instances via IAP only"
}

# Allow Google Load Balancer health checks to MIG
resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-lb-health-check"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags = ["mig"]
  description = "Allow Google Load Balancer health checks"
}
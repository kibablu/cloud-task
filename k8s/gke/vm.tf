# ------------------------------------------------
# 1. Bastion/Jump Host VM for Cluster Access
# ------------------------------------------------

# Bastion host VM instance
resource "google_compute_instance" "bastion_host" {
  name         = "bastion-host"
  machine_type = "e2-small" # A small, cost-effective machine type
  zone         = var.gcp_zone
  tags         = ["allow-ssh"] # Tag for the SSH firewall rule

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.bastion_subnet.self_link
    access_config {} # Assigns an ephemeral public IP for SSH access
  }
}
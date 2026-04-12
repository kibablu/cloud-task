resource "google_compute_instance" "bastion_host" {
  name         = "bastion-host"
  machine_type = "e2-small" 
  zone         = var.gcp_zone
  tags         = ["allow-ssh"] 

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

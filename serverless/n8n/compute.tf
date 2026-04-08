resource "google_compute_instance" "soccer_vm" {
  name         = "soccer-analytics-vm"
  machine_type = "e2-standard-8" 
  zone         = var.zone
  tags = ["ollama-server"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size = 100
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
    # Note: No access_config block here == No Public IP
  }
}
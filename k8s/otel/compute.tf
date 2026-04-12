# Static IP for External Ingress (gce) 
resource "google_compute_global_address" "ingress_static_ip" {
  name         = "chris-ingress-global"
}


resource "google_compute_instance" "bastion_vm" {
  name         = "chris-bastion-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["bastion-host"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Network interface with ephemeral public IP
  network_interface {
    subnetwork = google_compute_subnetwork.vm_subnet.id
    # An empty access_config block assigns an ephemeral public IP
    access_config {}
  }

  service_account {
    email  = google_service_account.bastion_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# --- Static IP for External Ingress (Traefik) ---
resource "google_compute_global_address" "ingress_static_ip" {
  name = "chris-ingress-ip"
}

# --- Bastion/Management VM with Static Public IP ---
resource "google_compute_address" "vm_static_ip" {
  name   = "chris-vm-static-ip"
  region = var.region
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

  # Network interface with the reserved static IP
  network_interface {
    subnetwork = google_compute_subnetwork.vm_subnet.id
    # No reserved static IP is assigned. Access_config enables ephemeral public IP.
    access_config {}
  }
}

resource "google_compute_network" "main" {
  name                    = "main-vpc"
  auto_create_subnetworks = false
  description             = "Primary VPC for WordPress deployment"
}

resource "google_compute_subnetwork" "main" {
  name                     = "main-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true # to talk to googple api since no public IP for MIG
  description              = "Subnet with private Google access for MIG and Cloud SQL"
}
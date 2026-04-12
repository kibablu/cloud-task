resource "google_compute_network" "chris_vpc" {
  name                    = "chris-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm_subnet" {
  name          = "vm-subnet"
  ip_cidr_range = "10.10.1.0/24" # This range (10.10.1.0/24) will be authorized
  region        = var.region
  network       = google_compute_network.chris_vpc.id
}

# Subnet for GKE Nodes (Primary IP Range)
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.10.2.0/24" # Example CIDR
  region        = var.region
  network       = google_compute_network.chris_vpc.id

  # Secondary ranges for GKE Pods and Services
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.20.0.0/16" 
  }
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.30.0.0/16" 
  }
}

# Cloud NAT for GKE outbound access 
resource "google_compute_router" "router" {
  name    = "chris-router"
  region  = var.region
  network = google_compute_network.chris_vpc.id
}

resource "google_compute_router_nat" "nat_config" {
  name   = "chris-nat"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  nat_ip_allocate_option = "AUTO_ONLY"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  subnetwork {
    name                    = google_compute_subnetwork.gke_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

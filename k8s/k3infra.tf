terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.40.0"
    }
  }
}
provider "google" {
  project = "projectID" 
  region  = "us-central1"
}

// Create a custom VPC network
resource "google_compute_network" "k3s_vpc" {
  name                    = "k3s-custom-network"
  auto_create_subnetworks = false 
  routing_mode            = "REGIONAL" 
}

// Create a custom subnet in us-central1
resource "google_compute_subnetwork" "k3s_subnet" {
  name          = "k3s-subnet-us-central1"
  ip_cidr_range = "10.0.1.0/27"     // Example CIDR, provides 30 usable IPs (2^5 - 2)
  network       = google_compute_network.k3s_vpc.id
  region        = "us-central1"
}

// Create a firewall rule to allow all incoming traffic
// WARNING: This rule allows all traffic from any source on all ports.
// This is generally not recommended for production environments.
// Please restrict the source_ranges and allowed protocols and ports as per k3s.
resource "google_compute_firewall" "allow_all_ingress" {
  name    = "k3s-allow-all-ingress"
  network = google_compute_network.k3s_vpc.name 
  allow {
    protocol = "all" 
  }
  source_ranges = ["0.0.0.0/0"] // Allows traffic from any IP address
  target_tags   = ["k3s-node"]    // Apply this rule to instances with the "k3s-node" tag
}

// Create the Virtual Machines

// First instance: k3-controlplane
resource "google_compute_instance" "k3_controlplane" {
  name         = "k3-controlplane"
  machine_type = "e2-standard-4"
  zone         = "us-central1-a" 

  tags = ["k3s-node", "k3s-controlplane"] // Tags for firewall rules and identification

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
      size  = 50                         
      labels = {
        environment = "k3s-lab"
        role        = "controlplane"
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k3s_subnet.id // Attach to our custom subnet
    access_config {
    }
  }

  // Metadata for enabling OS Login 
  metadata = {
    enable-oslogin = "TRUE"
  }

  scheduling {
    automatic_restart   = true    
    on_host_maintenance = "MIGRATE" 
  }
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform", 
    ]
  }

  allow_stopping_for_update = true // Allows instance to be stopped for updates
}

// Second instance: k3-workernode-1
resource "google_compute_instance" "k3_workernode_1" {
  name         = "k3-workernode-1"
  machine_type = "e2-medium"
  zone         = "us-central1-a" 

  tags = ["k3s-node", "k3s-worker"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30 
      labels = {
        environment = "k3s-lab"
        role        = "worker"
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k3s_subnet.id
    access_config {
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
  allow_stopping_for_update = true
}

// Third instance: k3-workernode-2
resource "google_compute_instance" "k3_workernode_2" {
  name         = "k3-workernode-2"
  machine_type = "e2-medium"
  zone         = "us-central1-b" // Placing in a different zone for basic availability

  tags = ["k3s-node", "k3s-worker"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
      labels = {
        environment = "k3s-lab"
        role        = "worker"
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k3s_subnet.id
    access_config {
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
  allow_stopping_for_update = true
}

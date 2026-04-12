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

resource "google_compute_network" "k3s_vpc" {
  name                    = "k3s-custom-network"
  auto_create_subnetworks = false 
  routing_mode            = "REGIONAL" 
}

resource "google_compute_subnetwork" "k3s_subnet" {
  name          = "k3s-subnet-us-central1"
  ip_cidr_range = "10.0.0.0/27"     // Example CIDR, provides 30 usable IPs (2^5 - 2)
  network       = google_compute_network.k3s_vpc.id
  region        = "us-central1"
}

resource "google_compute_firewall" "allow_all_ingress" {
  name    = "k3s-allow-all-ingress"
  network = google_compute_network.k3s_vpc.name 
  allow {
    protocol = "all" 
  }
  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["k3s-node"]    
}

resource "google_compute_instance" "k3_controlplane" {
  name         = "k3-controlplane"
  machine_type = "e2-standard-4"
  zone         = "us-central1-a" 

  tags = ["k3s-node", "k3s-controlplane"] 

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

resource "google_compute_instance" "k3_workernode_2" {
  name         = "k3-workernode-2"
  machine_type = "e2-medium"
  zone         = "us-central1-b" 

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

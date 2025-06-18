terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.35.0" 
    }
  }
}

provider "google" {
  project = "<provide projectID>" 
  region  = "us-central1"         
  zone    = "us-central1-a"       
}

// creates a new Virtual Private Cloud (VPC) network.
// we set auto_create_subnetworks to false because we will define a custom subnetwork.

resource "google_compute_network" "custom_vpc" {
  name                    = "custom-vpc-network"
  auto_create_subnetworks = false // We will create a custom subnet
  routing_mode            = "REGIONAL" 
}

// creates a subnetwork within our custom VPC.
// IP CIDR range is set to /28 2 * (32-28) IPs.

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet-us-central1"
  ip_cidr_range = "10.0.10.0/29" 
  network       = google_compute_network.custom_vpc.id
  region        = "us-central1"    
}

// creates a firewall rule that allows incoming TCP traffic on ports 22 (SSH), 80 (HTTP), and 3360 (custom).
// it applies to all instances within the vpc created.

resource "google_compute_firewall" "allow_custom_traffic" {
  name    = "fw-allow-ssh-http-custom-tcp"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3306"] 
  }

  source_ranges = ["0.0.0.0/0"] 
}

// creates a  virtual machine with the specified characteristics.

resource "google_compute_instance" "centos_vm" {
  name         = "my-centos-vm"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a" 

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-stream-9" 
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.custom_subnet.id
    access_config {
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}

resource "google_dns_managed_zone" "primary_zone" {
  name = "primary-zone"
  dns_name = "example.com."
  description = "A primary managed zone for example.com"
  visibility = "public"
  force_destroy = true
  labels = {
    "environment" = "production"
  }
}

# "A" Record for the root domain (example.com)
resource "google_dns_record_set" "root_a_record" {
  name = google_dns_managed_zone.primary_zone.dns_name
  type = "A"
  ttl = 300
  managed_zone = google_dns_managed_zone.primary_zone.name
  rrdatas = ["external IP"]
}

# "CNAME" Record for the "www" subdomain (www.example.com)
resource "google_dns_record_set" "www_cname_record" {
  name = "www.${google_dns_managed_zone.primary_zone.dns_name}"
  type = "CNAME"
  ttl = 300
  managed_zone = google_dns_managed_zone.primary_zone.name
  rrdatas = [google_dns_managed_zone.primary_zone.dns_name]
}

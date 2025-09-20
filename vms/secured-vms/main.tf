# 1. Create a Custom VPC Network
resource "google_compute_network" "custom_vpc_network" {
  name                    = "secured-ecom-vpc"
  auto_create_subnetworks = false # We will create a custom subnetwork
  description             = "Custom VPC network for the VMs"
}

# 2. Create a Subnet within the Custom VPC
resource "google_compute_subnetwork" "custom_subnet" {
  name          = "secured-ecom-subnet"
  ip_cidr_range = "10.0.1.0/27" # /27 CIDR range
  region        = var.gcp_region
  network       = google_compute_network.custom_vpc_network.id
  description   = "Subnet for the VMs with a /27 CIDR"
}

# 3. Create Firewall Rules

# 3.1. DB ingress from webserver internal IP on port 3306
resource "google_compute_firewall" "allow_webserver_to_db" {
  name        = "allow-webserver-to-db"
  network     = google_compute_network.custom_vpc_network.id
  description = "Allow webserver to connect to DB on port 3306"

  direction = "INGRESS"
  # Target the 'db' VM
  target_tags = ["db"]
  # Source is the 'webserver' VM
  source_tags = ["webserver"]

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
}

# 3.2. Webserver ingress from proxy internal IP on port 80 and 443
resource "google_compute_firewall" "allow_proxy_to_webserver" {
  name        = "allow-proxy-to-webserver"
  network     = google_compute_network.custom_vpc_network.id
  description = "Allow proxy to connect to webserver on ports 80 and 443"

  direction = "INGRESS"
  # Target the 'webserver' VM
  target_tags = ["webserver"]
  # Source is the 'proxy' VM
  source_tags = ["proxy"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# 3.3. Proxy ingress from all on port 80 and 443
resource "google_compute_firewall" "allow_all_to_proxy" {
  name        = "allow-all-to-proxy"
  network     = google_compute_network.custom_vpc_network.id
  description = "Allow external traffic to proxy on ports 80 and 443"

  direction = "INGRESS"
  # Target the 'proxy' VM
  target_tags = ["proxy"]
  # Source is all IP addresses
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# 3.4. Bastion ingress of port 22
resource "google_compute_firewall" "allow_ssh_to_bastion" {
  name        = "allow-ssh-to-bastion"
  network     = google_compute_network.custom_vpc_network.id
  description = "Allow SSH access to the bastion host"

  direction = "INGRESS"
  # Target the 'bastion' VM
  target_tags = ["bastion"]
  # Source is all IP addresses
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# 3.5. Allow SSH from Bastion to internal VMs
resource "google_compute_firewall" "allow_bastion_ssh" {
  name    = "allow-bastion-ssh"
  network = google_compute_network.custom_vpc_network.id

  description = "Allow SSH access from bastion to webserver, proxy, and db"
  direction   = "INGRESS"

  # Applies to all VMs with these tags
  target_tags = ["webserver", "proxy", "db"]
  source_tags = ["bastion"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# 4. Create VM Instances

# 4.1. Bastion Host with Public IP
resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-medium" 
  zone         = var.gcp_zone
  tags         = ["bastion"] # Network tag for firewall rules

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = google_compute_network.custom_vpc_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id
    # Assign a public IP for external access
    access_config {}
  }
}

# 4.2. Webserver VM with No External IP
resource "google_compute_instance" "webserver" {
  name         = "webserver"
  machine_type = "e2-medium" 
  zone         = var.gcp_zone
  tags         = ["webserver"] # Network tag for firewall rules

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = google_compute_network.custom_vpc_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id
    # No access_config block means no external IP
  }
}

# 4.3. DB VM with No External IP
resource "google_compute_instance" "db" {
  name         = "db"
  machine_type = "e2-medium" 
  zone         = var.gcp_zone
  tags         = ["db"] # Network tag for firewall rules

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = google_compute_network.custom_vpc_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id
    # No access_config block means no external IP
  }
}

# 4.4. Proxy VM with an External IP
resource "google_compute_instance" "proxy" {
  name         = "proxy"
  machine_type = "e2-medium" 
  zone         = var.gcp_zone
  tags         = ["proxy"] # Network tag for firewall rules

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = google_compute_network.custom_vpc_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id
    # Assign a public IP for external access
    access_config {}
  }
}

# 5. Create Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = var.gcp_region
  network = google_compute_network.custom_vpc_network.id
}

# 6. Create Cloud NAT
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "secured-ecom-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
  # log_config block is removed to turn off logging
}

# Create a public managed zone for example.com
resource "google_dns_managed_zone" "primary" {
  name        = "ecom-dns"
  dns_name    = "example.com."
  description = "Managed by Terraform"
}

# Create an A record for the root domain (example.top)
resource "google_dns_record_set" "root_a_record" {
  name         = "${google_dns_managed_zone.primary.dns_name}"
  managed_zone = google_dns_managed_zone.primary.name
  type         = "A"
  ttl          = 300
  rrdatas      = ["Proxy External IP"]
}

# Create a CNAME record for the www subdomain (www.example.com)
resource "google_dns_record_set" "www_cname_record" {
  name         = "www.${google_dns_managed_zone.primary.dns_name}"
  managed_zone = google_dns_managed_zone.primary.name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["${google_dns_managed_zone.primary.dns_name}"]
}

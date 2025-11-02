# Firewall rule to allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  name          = "allow-internal-gke-vpc"
  network       = google_compute_network.vpc.self_link
  source_ranges = [var.vpc_cidr] # Allow all traffic within the VPC
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  depends_on = [google_compute_network.vpc]
}

# Firewall rule to allow SSH access to the bastion host
resource "google_compute_firewall" "allow_ssh_to_bastion" {
  name    = "allow-ssh-to-bastion"
  network = google_compute_network.vpc.self_link

  # Allow TCP traffic on port 22 (SSH)
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IMPORTANT: For production, you should restrict this to your own IP address.
  # Example: source_ranges = ["YOUR_HOME_OR_OFFICE_IP/32"]
  source_ranges = ["0.0.0.0/0"]

  # Apply this rule only to instances with the 'allow-ssh' tag
  target_tags = ["allow-ssh"]
}
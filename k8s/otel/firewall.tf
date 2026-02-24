resource "google_compute_firewall" "allow_ssh_from_bastion_to_nodes" {
  name    = "allow-ssh-from-bastion"
  network = google_compute_network.chris_vpc.name # Replace with your VPC name
  
  # Allow SSH
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Target the nodes (GKE adds 'gke-cluster-name' tags automatically, 
  target_tags = ["gke-node"] 

  # Only allow the internal range of your VPC/Bastion Subnet
  source_ranges = [google_compute_subnetwork.vm_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "allow_ssh_to_bastion" {
  name    = "allow-ssh-to-bastion-from-anywhere"
  network = google_compute_network.chris_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # This rule targets the bastion VM. Ensure your bastion VM instance
  # has the "bastion-vm" network tag.
  target_tags = ["bastion-host"]

  source_ranges = ["0.0.0.0/0"]
}
# Firewall Rule for IAP SSH
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-ssh-from-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # This is the mandatory Google IAP IP range
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_n8n_to_ollama" {
  name    = "allow-n8n-to-ollama"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["11434"]
  }

  # Source is the connector's subnet range
  source_ranges = ["10.8.0.0/28"]
  target_tags   = ["ollama-server"]
}

# Allow the Compute Engine VM to talk to the Soccer MCP via the internal network
resource "google_compute_firewall" "allow_vm_to_mcp" {
  name    = "allow-vm-to-mcp"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  # Source: The Private VM Subnet
  source_ranges = ["10.0.1.0/24"]
  # Target: The VPC Connector IP range
  target_tags   = ["soccer-mcp-internal"]
}
# Create a dedicated subnet for the connector
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "n8n-vpc-connector-subnet"
  ip_cidr_range = "10.8.0.0/28" 
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# Connector itself
resource "google_vpc_access_connector" "connector" {
  name          = "n8n-to-ollama"
  region        = "us-central1"
  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }
  # Minimal scaling to keep costs low
  min_instances = 2
  max_instances = 3
}

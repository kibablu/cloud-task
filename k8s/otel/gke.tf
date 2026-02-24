# --- GKE Cluster ---
resource "google_container_cluster" "chris_gke_cluster" {
  name       = "chris-gke-public"
  location   = var.zone
  network    = google_compute_network.chris_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1 

  min_master_version  = "latest"
  deletion_protection = false

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0" # WARNING: Open to the world. Replace with your IP.
      display_name = "Public Access"
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }
}

# --- Custom Node Pool ---
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.chris_gke_cluster.name
  
  initial_node_count = 1

  autoscaling {
    min_node_count = 2
    max_node_count = 5
  }

  node_config {
    machine_type = "e2-standard-4"
    disk_type    = "pd-balanced"
    disk_size_gb = 50
    tags         = ["gke-node"]

    # Removed custom service account to use the Compute Engine default service account
    # If you want to be explicit, you can omit the service_account line entirely.

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}
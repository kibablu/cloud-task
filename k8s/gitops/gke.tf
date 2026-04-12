resource "google_container_cluster" "chris_gke_cluster" {
  name       = "chris-gke-private"
  location   = var.zone
  network    = google_compute_network.chris_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = "latest"

  deletion_protection = false

  # Private Cluster Config
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    #  master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master Authorized Networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = google_compute_subnetwork.vm_subnet.ip_cidr_range
      display_name = "Bastion VM Subnet Access"
    }
  }

  # Workload Identity (Cluster Level)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Addons
  addons_config {
    # Explicitly enable the Persistent Disk CSI driver.
    # This supports the default StorageClass "standard-rwo" which uses Balanced SSDs (pd-balanced).
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  secret_manager_config {
    enabled = true
  }

  # IP Aliasing
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
  node_count = 1

  node_config {
    machine_type = "e2-medium"

    disk_type    = "pd-balanced"
    disk_size_gb = 20

    service_account = google_service_account.gke_node_sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

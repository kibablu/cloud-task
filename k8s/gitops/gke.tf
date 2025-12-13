# --- GKE Cluster ---
resource "google_container_cluster" "chris_gke_cluster" {
  name       = "chris-gke-private"
  location   = var.zone
  network    = google_compute_network.chris_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # We remove default node pool so we can manage our own custom pool below
  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = "latest"

  # --- ENABLE DELETION ---
  # This allows 'terraform destroy' to delete the cluster. 
  # Without this, the destroy command will fail.
  deletion_protection = false

  # 1. Private Cluster Config
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    #  master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # 2. Master Authorized Networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = google_compute_subnetwork.vm_subnet.ip_cidr_range
      display_name = "Bastion VM Subnet Access"
    }
  }

  # 3. Workload Identity (Cluster Level)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # 4. Addons
  addons_config {
    # Explicitly enable the Persistent Disk CSI driver.
    # This supports the default StorageClass "standard-rwo" which uses Balanced SSDs (pd-balanced).
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # 5. Secret Manager (Moved to Root Level - Fixes Syntax Error)
  secret_manager_config {
    enabled = true
  }

  # 6. IP Aliasing
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

    # Optional: Set the boot disk of the Node itself to Balanced SSD 
    # (Default is usually pd-standard or pd-balanced depending on zone)
    disk_type    = "pd-balanced"
    disk_size_gb = 20

    # 1. Use the explicit Node SA (Infrastructure Only)
    service_account = google_service_account.gke_node_sa.email

    # 2. Standard scopes required for GKE and Workload Identity
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
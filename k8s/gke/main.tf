# ------------------------------------------------
# 1. GKE Clusters (app, db, ops)
# ------------------------------------------------
resource "google_container_cluster" "clusters" {
  for_each = var.subnet_configs
  name     = "gke-${each.key}-cluster"
  location = var.gcp_zone

  # Basic configuration
  initial_node_count = 1
  release_channel { channel = var.gke_release_channel }

  # Allow deletion of the cluster through Terraform. Defaults to true.
  deletion_protection = false

  # Define the configuration for the initial, temporary node pool to avoid quota issues.
  node_config {
    disk_type    = "pd-balanced"
    disk_size_gb = 20 # Increased to meet minimum image requirements (12GB)
  }

  # Requirement 1: Network/Subnet configuration
  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnets[each.key].self_link

  # Requirement 2: No public IP (Private Cluster)
  private_cluster_config {
    enable_private_endpoint = true # Allows access from within the VPC
    enable_private_nodes    = true # Ensures nodes have no public IP
    # Assign non-overlapping master CIDR block per cluster
    master_ipv4_cidr_block = each.key == "app" ? "172.16.0.0/28" : (each.key == "db" ? "172.16.1.0/28" : "172.16.2.0/28")
  }

  # Must be enabled when using private_endpoint
  master_authorized_networks_config {
    cidr_blocks {
      # Allow access to the master from the cluster's own subnet.
      cidr_block   = google_compute_subnetwork.subnets[each.key].ip_cidr_range
      display_name = "Primary subnet range for ${each.key}-subnet"
    }
    cidr_blocks {
      # Allow access from the bastion/jump host subnet
      cidr_block   = var.bastion_subnet_cidr
      display_name = "Bastion/Jump Host Subnet"
    }
  }

  # Requirement 6: Dataplane V2 CNI
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnets[each.key].secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnets[each.key].secondary_ip_range[1].range_name
  }

  # Dataplane V2 CNI implementation (ADVANCED_DATAPATH)
  datapath_provider = "ADVANCED_DATAPATH"

  # Requirement 5: Enable Security Features
  # Workload Identity Pool setup (Req 5)
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Security Posture (Req 5)
  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  # Requirement 7: Cloud DNS
  dns_config {
    cluster_dns        = "CLOUD_DNS"                 # Use Cloud DNS for in-cluster DNS resolution
    cluster_dns_scope  = "VPC_SCOPE"                 # Sets cluster DNS to Cloud DNS for VPC
    cluster_dns_domain = "${each.key}.cluster.local" # Required when using VPC_SCOPE with Cloud DNS
  }

  # Requirement 8 & 10: Add-ons Configuration
  addons_config {
    # HTTP Load Balancing (Enabled only for 'app' cluster)
    http_load_balancing {
      disabled = each.key != "app"
    }

    # Compute Engine Persistent Disk CSI Driver (Req 10)
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Requirement 9: Disable Logging, Monitoring, and Managed Prometheus
  logging_config {
    enable_components = [] # Disable all logging components
  }

  monitoring_config {
    enable_components = [] # Disable all monitoring components
    managed_prometheus {
      enabled = false
    }
  }

  # Remove default node pool as we define a custom one below
  remove_default_node_pool = true
}

# ------------------------------------------------
# Node Pool Definitions
# ------------------------------------------------
resource "google_container_node_pool" "node_pools" {
  for_each   = google_container_cluster.clusters
  cluster    = each.value.name
  location   = var.gcp_zone
  name       = "${each.key}-pool"
  node_count = 1

  node_config {
    machine_type = "e2-medium" # Requirement 3: E2-medium
    spot         = true        # Requirement 3: Spot VMs

    # Requirement 4: Attach service account
    # This depends on a service account resource, google_service_account.gke_node_sa'
    
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Requirement 5: Shielded GKE Nodes (integrated with node config)
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    # Node boot disk configuration
    disk_type    = "pd-balanced" # Use pd-balanced for all node boot disks to avoid SSD quota issues.
    disk_size_gb = 30            # Set a consistent 10GB size for all boot disks.
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

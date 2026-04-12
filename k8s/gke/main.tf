resource "google_container_cluster" "clusters" {
  for_each = var.subnet_configs
  name     = "gke-${each.key}-cluster"
  location = var.gcp_zone

  initial_node_count = 1
  release_channel { channel = var.gke_release_channel }

  deletion_protection = false

  node_config {
    disk_type    = "pd-balanced"
    disk_size_gb = 20 
  }

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnets[each.key].self_link

  # No public IP (Private Cluster)
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
    cidr_blocks {
      # Allow access from the ArgoCD cluster subnet
      cidr_block   = var.argocd_subnet_cidr
      display_name = "ArgoCD Subnet"
    }
  }

  # Dataplane V2 CNI
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnets[each.key].secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnets[each.key].secondary_ip_range[1].range_name
  }

  # Dataplane V2 CNI 
  datapath_provider = "ADVANCED_DATAPATH"

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  confidential_nodes {
    enabled = false 
  }

  # Security Posture 
  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  # Cloud DNS
  dns_config {
    cluster_dns        = "CLOUD_DNS"                
    cluster_dns_scope  = "VPC_SCOPE"                 
    cluster_dns_domain = "${each.key}.cluster.local" 
  }

  # Add-ons Configuration
  addons_config {
    # HTTP Load Balancing (Enabled only for 'app' cluster)
    http_load_balancing {
      disabled = each.key != "app"
    }

    # Compute Engine Persistent Disk CSI Driver
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Disable Logging, Monitoring, and Managed Prometheus
  logging_config {
    enable_components = [] 
  }

  monitoring_config {
    enable_components = [] 
    managed_prometheus {
      enabled = false
    }
  }

  remove_default_node_pool = true
}

resource "google_container_node_pool" "node_pools" {
  for_each   = google_container_cluster.clusters
  cluster    = each.value.name
  location   = var.gcp_zone
  name       = "${each.key}-pool"
  node_count = 1

  node_config {
    machine_type = "e2-medium" 
   # spot         = true        

    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    disk_type    = "pd-balanced" 
    disk_size_gb = 30            
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

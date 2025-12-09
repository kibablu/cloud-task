# ------------------------------------------------
# ArgoCD GKE Cluster
# ------------------------------------------------
resource "google_container_cluster" "argocd_cluster" {
  name     = "gke-argocd-cluster"
  location = "${var.gcp_region}-b" # Using a single zone

  # Allow deletion of the cluster through Terraform
  deletion_protection = false

  # Initial node count for default node pool
  initial_node_count = 1
  release_channel { channel = var.gke_release_channel }

  # Network/Subnet configuration
  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.argocd_subnet.self_link

  # Use default node pool and service account
  node_config {
    # Machine type
    machine_type = "e2-medium"

    # Disk configuration
    disk_type    = "pd-balanced"
    disk_size_gb = 20

    # Use default service account
    service_account = "default"

    # Use default OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.argocd_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.argocd_subnet.secondary_ip_range[1].range_name
  }

  # Make cluster public but restrict control plane access
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = false
  }

  # Restrict control plane access to bastion subnet
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.bastion_subnet_cidr
      display_name = "Bastion/Jump Host Subnet"
    }
  }

  # Disable logging
  logging_config {
    enable_components = []
  }

  # Disable monitoring
  monitoring_config {
    enable_components = []
  }

  # Disable Workload Identity by default
  workload_identity_config {
    workload_pool = null
  }

}

# ------------------------------------------------
# Helm Release for ArgoCD
# ------------------------------------------------
resource "helm_release" "argocd" {
  provider = helm.argocd_gke

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "5.51.2"
  create_namespace = true

  # Configure values for the ArgoCD chart to use LoadBalancer
  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [google_container_cluster.argocd_cluster]
}

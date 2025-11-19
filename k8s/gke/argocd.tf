# ------------------------------------------------
# 1. ArgoCD GKE Cluster
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
# 2. Helm Release for ArgoCD
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

# # ------------------------------------------------
# # 6. ArgoCD Autopilot GKE Cluster
# # ------------------------------------------------
# resource "google_container_cluster" "argocd_cluster" {
#   name     = "gke-argocd-cluster"
#   location = "${var.gcp_region}-b"  # Using a single zone

#   # Allow deletion of the cluster through Terraform
#   deletion_protection = false

#   # Initial node count for default node pool
#   initial_node_count = 1
#   release_channel { channel = var.gke_release_channel }

#   # Network/Subnet configuration
#   network    = google_compute_network.vpc.self_link
#   subnetwork = google_compute_subnetwork.argocd_subnet.self_link

#   # Use default node pool and service account
#   node_config {
#     # Machine type
#     machine_type = "e2-medium"

#     # Disk configuration
#     disk_type    = "pd-balanced"
#     disk_size_gb = 20

#     # Use default service account
#     service_account = "default"

#     # Use default OAuth scopes
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#   }

#   # IP allocation policy for VPC-native cluster
#   ip_allocation_policy {
#     cluster_secondary_range_name  = google_compute_subnetwork.argocd_subnet.secondary_ip_range[0].range_name
#     services_secondary_range_name = google_compute_subnetwork.argocd_subnet.secondary_ip_range[1].range_name
#   }

#   # Make cluster public but restrict control plane access
#   private_cluster_config {
#     enable_private_endpoint = false
#     enable_private_nodes   = false
#   }

#   # Restrict control plane access to bastion subnet
#   master_authorized_networks_config {
#     cidr_blocks {
#       cidr_block   = var.bastion_subnet_cidr
#       display_name = "Bastion/Jump Host Subnet"
#     }
#   }

#   # Enable GCE Ingress Controller
#   addons_config {
#     http_load_balancing {
#       disabled = false  # Enable GCE ingress controller
#     }
#   }

#   # Disable logging
#   logging_config {
#     enable_components = []
#   }

#   # Disable monitoring
#   monitoring_config {
#     enable_components = []
#   }

#   # Disable Workload Identity by default
#   workload_identity_config {
#     workload_pool = null
#   }
# }

# # ------------------------------------------------
# # 7. DNS for ArgoCD
# # ------------------------------------------------
# resource "google_dns_managed_zone" "argocd_zone" {
#   name     = var.dns_zone_name
#   dns_name = "${var.argocd_dns_record}." # Must end with a dot
#   project  = var.gcp_project_id
# }

# resource "google_dns_record_set" "argocd_record" {
#   name = "${var.argocd_dns_record}."
#   type = "A"
#   ttl  = 300

#   # This will be populated once the Ingress is created and an IP is assigned.
#   # For now, we use a placeholder. You will need to update this manually
#   # or use an external-dns controller in your cluster.
#   rrdatas = [google_compute_address.app_external_ip.address]

#   managed_zone = google_dns_managed_zone.argocd_zone.name
#   project      = var.gcp_project_id
# }

# # ------------------------------------------------
# # 8. Google-Managed SSL Certificate for ArgoCD
# # ------------------------------------------------
# resource "google_compute_managed_ssl_certificate" "argocd_ssl_cert" {
#   name = "argocd-managed-cert"
#   managed {
#     domains = [var.argocd_dns_record]
#   }
#   project = var.gcp_project_id
# }

# # ------------------------------------------------
# # 9. Helm Release for ArgoCD
# # ------------------------------------------------
# resource "helm_release" "argocd" {
#   # Use the aliased providers configured in provider.tf
#   provider = helm.argocd_gke

#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   namespace  = "argocd"
#   version    = "5.51.2" # Pinning chart version is a best practice

#   create_namespace = true

#   # Configure values for the ArgoCD chart
#   values = [
#     yamlencode({
#       server = {
#         ingress = {
#           enabled      = true
#           ingressClassName = "gce" # Use GKE's default Ingress controller
#           hosts        = [var.argocd_dns_record]
#           annotations = {
#             # Use the Google-managed SSL certificate
#             "networking.gke.io/managed-certificates" = google_compute_managed_ssl_certificate.argocd_ssl_cert.name
#           }
#         }
#       }
#     })
#   ]

#   # Ensure the GKE cluster is ready before attempting to install the Helm chart
#   depends_on = [google_container_cluster.argocd_cluster]
# }
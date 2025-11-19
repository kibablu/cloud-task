# ------------------------------------------------
# Network Setup (VPC, Subnets, and NAT)
# ------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "${var.gcp_project_id}-gke-vpc"
  auto_create_subnetworks = false # Custom subnets for better control
  routing_mode            = "REGIONAL"
  depends_on              = [google_project_service.gcp_apis]
}

# Create three subnets with secondary ranges for GKE (Pods/Services)
resource "google_compute_subnetwork" "subnets" {
  for_each      = var.subnet_configs
  name          = "${each.key}-subnet"
  ip_cidr_range = each.value.ip_cidr_range
  region        = var.gcp_region
  network       = google_compute_network.vpc.self_link

  secondary_ip_range {
    range_name    = "${each.key}-pods"
    ip_cidr_range = each.value.pods_secondary_range
  }

  secondary_ip_range {
    range_name    = "${each.key}-services"
    ip_cidr_range = each.value.services_secondary_range
  }
}

# ------------------------------------------------
# Subnet for the Bastion/Jump Host VM
# ------------------------------------------------
resource "google_compute_subnetwork" "bastion_subnet" {
  name          = "bastion-subnet"
  ip_cidr_range = var.bastion_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.self_link
}

# ------------------------------------------------
# Subnet for the ArgoCD Autopilot GKE Cluster
# ------------------------------------------------
resource "google_compute_subnetwork" "argocd_subnet" {
  name          = "argocd-subnet"
  ip_cidr_range = var.argocd_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.self_link

  secondary_ip_range {
    range_name    = "argocd-pods"
    ip_cidr_range = var.argocd_pods_secondary_range
  }
  secondary_ip_range {
    range_name    = "argocd-services"
    ip_cidr_range = var.argocd_services_secondary_range
  }
}
# ------------------------------------------------
# Reserve Static Public IP for the App Load Balancer
# ------------------------------------------------
resource "google_compute_address" "app_external_ip" {
  name         = "${var.gcp_project_id}-app-external-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  region       = var.gcp_region
}

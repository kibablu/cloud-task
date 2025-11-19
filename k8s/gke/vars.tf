variable "gcp_project_id" {
  description = "The ID of the GCP project where resources will be created"
  type        = string
  default     = "PROJECT_ID" # !!! CHANGE THIS !!!
}

variable "gcp_region" {
  description = "The GCP region for the GKE clusters (Regional best practice)"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP zone for the GKE clusters"
  type        = string
  default     = "us-central1-a"
}

variable "gke_release_channel" {
  description = "The release channel for GKE clusters (e.g., REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "vpc_cidr" {
  description = "The CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_configs" {
  description = "Configuration for the three environment-specific subnets"
  type = map(object({
    ip_cidr_range            = string
    pods_secondary_range     = string
    services_secondary_range = string
  }))
  default = {
    app = {
      ip_cidr_range            = "10.0.10.0/24"
      pods_secondary_range     = "10.10.0.0/18"
      services_secondary_range = "10.20.0.0/20"
    }
    db = {
      ip_cidr_range            = "10.0.20.0/24"
      pods_secondary_range     = "10.11.0.0/18"
      services_secondary_range = "10.21.0.0/20"
    }
    ops = {
      ip_cidr_range            = "10.0.30.0/24"
      pods_secondary_range     = "10.12.0.0/18"
      services_secondary_range = "10.22.0.0/20"
    }
  }
}

variable "bastion_subnet_cidr" {
  description = "The CIDR range for the bastion/management subnet"
  type        = string
  default     = "10.0.1.0/28"
}

variable "argocd_subnet_cidr" {
  description = "The CIDR range for the ArgoCD Autopilot GKE cluster subnet"
  type        = string
  default     = "10.0.40.0/24"
}

variable "argocd_pods_secondary_range" {
  description = "The secondary CIDR range for the ArgoCD cluster Pods"
  type        = string
  default     = "10.13.0.0/18"
}

variable "argocd_services_secondary_range" {
  description = "The secondary CIDR range for the ArgoCD cluster Services"
  type        = string
  default     = "10.23.0.0/20"
}

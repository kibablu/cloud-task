variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone for the zonal GKE cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name prefix used for the cluster and all related resources"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR for GKE nodes"
  type        = string
}

variable "pods_cidr" {
  description = "Secondary CIDR for GKE pods"
  type        = string
}

variable "services_cidr" {
  description = "Secondary CIDR for GKE services"
  type        = string
}

variable "master_cidr" {
  description = "CIDR for the GKE control-plane private endpoint (must be /28)"
  type        = string
}

variable "authorized_networks" {
  description = "CIDRs allowed to reach the public GKE master endpoint"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

variable "machine_type" {
  description = "GCE machine type for nodes — e2-standard-4 recommended for Istio sidecar overhead"
  type        = string
}

variable "node_count" {
  description = "Initial node count"
  type        = number
}

variable "node_min_count" {
  description = "Minimum nodes for autoscaling"
  type        = number
}

variable "node_max_count" {
  description = "Maximum nodes for autoscaling"
  type        = number
}

variable "disk_size_gb" {
  description = "Boot disk size per node in GB"
  type        = number
}

variable "labels" {
  description = "Labels applied to all GCP resources"
  type        = map(string)
}
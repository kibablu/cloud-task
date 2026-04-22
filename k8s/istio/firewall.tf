# Allow GKE master to reach nodes for Istio webhook (15017) and admission webhooks (8443)
resource "google_compute_firewall" "gke_master_to_nodes" {
  name        = "${var.cluster_name}-master-to-nodes"
  network     = google_compute_network.vpc.id
  description = "GKE master → nodes: Istio webhook (15017), admission (8443), kubelet (10250)"

  allow {
    protocol = "tcp"
    ports    = ["8443", "10250", "15017"]
  }

  source_ranges = [var.master_cidr]
  target_tags   = ["gke-${var.cluster_name}"]
}

# Istio control-plane ports between pods and nodes
resource "google_compute_firewall" "istio_control_plane" {
  name        = "${var.cluster_name}-istio-control-plane"
  network     = google_compute_network.vpc.id
  description = "Istiod xDS (15010/15012), monitoring (15014), webhook (15017)"

  allow {
    protocol = "tcp"
    ports    = ["15010", "15012", "15014", "15017"]
  }

  source_ranges = [var.pods_cidr, var.subnet_cidr]
  target_tags   = ["gke-${var.cluster_name}"]
}

# Envoy sidecar data-plane ports
resource "google_compute_firewall" "istio_data_plane" {
  name        = "${var.cluster_name}-istio-data-plane"
  network     = google_compute_network.vpc.id
  description = "Envoy sidecar: inbound (15006), outbound (15001), health (15021), metrics (15020/15090)"

  allow {
    protocol = "tcp"
    ports    = ["15001", "15006", "15008", "15020", "15021", "15090"]
  }

  source_ranges = [var.pods_cidr, var.subnet_cidr]
  target_tags   = ["gke-${var.cluster_name}"]
}

# External traffic into the Istio Ingress Gateway LoadBalancer
resource "google_compute_firewall" "istio_ingress_gateway" {
  name        = "${var.cluster_name}-istio-ingress"
  network     = google_compute_network.vpc.id
  description = "Allow HTTP/HTTPS from internet to Istio Ingress Gateway"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-${var.cluster_name}"]
}

# GCP health-check probes (required for LoadBalancer backends)
resource "google_compute_firewall" "gcp_health_checks" {
  name        = "${var.cluster_name}-health-checks"
  network     = google_compute_network.vpc.id
  description = "GCP health-check source ranges"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    "209.85.152.0/22",
    "209.85.204.0/22",
  ]

  target_tags = ["gke-${var.cluster_name}"]
}

# Pod-to-pod traffic (mTLS inside the mesh)
resource "google_compute_firewall" "pods_internal" {
  name        = "${var.cluster_name}-pods-internal"
  network     = google_compute_network.vpc.id
  description = "All pod-to-pod traffic within the pod CIDR"

  allow {
    protocol = "all"
  }

  source_ranges = [var.pods_cidr]
  target_tags   = ["gke-${var.cluster_name}"]
}

# Node-to-node traffic within the subnet
resource "google_compute_firewall" "nodes_internal" {
  name        = "${var.cluster_name}-nodes-internal"
  network     = google_compute_network.vpc.id
  description = "All node-to-node traffic within the subnet"

  allow {
    protocol = "all"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["gke-${var.cluster_name}"]
}
# Cloud Router (NAT prerequisite)
resource "google_compute_router" "medic_nat_router" {
  name    = "medic-nat-router"
  network = google_compute_network.vpc.self_link
  region  = var.gcp_region
}

# Cloud NAT Gateway (Covers all 3 subnets for outbound internet access)
resource "google_compute_router_nat" "medic_cloud_nat" {
  name                               = "medic-cloud-nat"
  router                             = google_compute_router.medic_nat_router.name
  region                             = google_compute_router.medic_nat_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # Map subnets to NAT
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.subnets
    content {
      name                    = subnetwork.value.self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Ensures the NAT is dependent on the router being ready.
  # The dependency on the subnets is implicitly handled by the dynamic "subnetwork" block above.
  depends_on = [
    google_compute_router.medic_nat_router
  ]
}

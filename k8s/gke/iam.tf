# ------------------------------------------------
# 1. IAM Service Account for GKE Nodes & Permissions
# ------------------------------------------------
# Requirement 4: Create a service account
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account with Secret Accessor"
  depends_on   = [google_project_service.gcp_apis]
}

# Requirement 4: Grant Secret Manager Secret Accessor role
resource "google_project_iam_member" "secret_accessor_role" {
  project    = var.gcp_project_id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.gke_node_sa.email}"
  depends_on = [google_service_account.gke_node_sa]
}

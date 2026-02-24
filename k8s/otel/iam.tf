# The Service Account for the Bastion VM
resource "google_service_account" "bastion_sa" {
  account_id   = "gke-bastion-sa"
  display_name = "GKE Bastion Service Account"
}

# Assigning the Admin role so it can manage K8s resources
resource "google_project_iam_member" "bastion_gke_access" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}
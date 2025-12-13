# Create the Google Service Account (GSA) ---
resource "google_service_account" "gke_workload_sa" {
  account_id   = "chris-app-gsa"
  display_name = "Chris App Workload Identity SA"
}

# Grant GSA access to Secret Manager ---
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.postgres_creds.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_workload_sa.email}"
}

# Bind K8s Service Account (KSA) to Google Service Account (GSA) ---
# This is the critical Workload Identity step.
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.gke_workload_sa.name
  role               = "roles/iam.workloadIdentityUser"

  # member format: "serviceAccount:PROJECT_ID.svc.id.goog[K8S_NAMESPACE/K8S_SA_NAME]"
  # We assume you will create a K8s SA named 'chris-sa' in namespace 'chris'
  member = "serviceAccount:${var.project_id}.svc.id.goog[chris/chris-sa]"
}

# --- Dedicated Service Account for GKE Nodes (VMs) ---
# Nodes only need permissions to write logs and pull images.
resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "node_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

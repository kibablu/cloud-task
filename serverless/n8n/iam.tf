# Find the default Cloud Build Service Account
data "google_project" "project" {}

locals {
  cb_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Permission to push images to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "cb_registry_writer" {
  location   = var.region
  repository = "soccermcp"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${local.cb_service_account}"
}

# Permission to deploy to Cloud Run
resource "google_project_iam_member" "cb_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${local.cb_service_account}"
}

# Permission for Cloud Build to act as the Cloud Run runtime service account
resource "google_service_account_iam_member" "cb_sa_user" {
  service_account_id = google_service_account.cloud_run_sa.name
  
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${local.cb_service_account}"
}

# Permission to use the Serverless VPC Connector
resource "google_project_iam_member" "cb_vpc_user" {
  project = var.project_id
  role    = "roles/vpcaccess.user"
  member  = "serviceAccount:${local.cb_service_account}"
}

# Permission to view network settings (required to validate the connector)
resource "google_project_iam_member" "cb_network_viewer" {
  project = var.project_id
  role    = "roles/compute.networkViewer"
  member  = "serviceAccount:${local.cb_service_account}"
}

# Permission to write build logs
resource "google_project_iam_member" "cb_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cb_service_account}"
}

# n8n Service Account
resource "google_service_account" "cloud_run_sa" {
  account_id   = "n8n-runner"
  display_name = "n8n Cloud Run Runtime Identity"
}

# This allows the n8n-runner to act as a "Builder"
resource "google_project_iam_member" "n8n_as_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Cloud SQL Client (To connect to Postgres)
resource "google_project_iam_member" "n8n_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Secret Manager Accessor (To read n8n encryption keys/DB passwords)
resource "google_project_iam_member" "n8n_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant VPC Access (Required for the VPC Connector to work)
resource "google_project_iam_member" "n8n_vpc_user" {
  project = var.project_id
  role    = "roles/vpcaccess.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Allow n8n to call the MCP service
resource "google_cloud_run_v2_service_iam_member" "n8n_invoker_mcp" {
  name     = google_cloud_run_v2_service.soccer_mcp.name
  location = google_cloud_run_v2_service.soccer_mcp.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Allow IAP to reach Cloud Run
resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  name     = google_cloud_run_v2_service.n8n.name
  location = google_cloud_run_v2_service.n8n.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}

# Gives the Google-managed Cloud Run Agent the ability to act as a system observer
resource "google_project_iam_member" "cloud_run_agent_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# Allows the n8n-runner (acting as the builder) to manage Cloud Run
resource "google_project_iam_member" "n8n_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Allows the service account to "use" itself when deploying
resource "google_service_account_iam_member" "n8n_self_user" {
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
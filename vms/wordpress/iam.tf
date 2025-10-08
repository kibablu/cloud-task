resource "google_service_account" "mig_sa" {
  account_id   = "mig-sa"
  display_name = "Service account for MIG instances"
}

resource "google_project_iam_member" "mig_sa_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/cloudsql.editor",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin",
    "roles/storage.objectViewer"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.mig_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "db_user_access" {
  secret_id = google_secret_manager_secret.db_user.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.mig_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.mig_sa.email}"
}
resource "google_secret_manager_secret" "db_user" {
  secret_id = "super-user"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "super-secret-id"
  replication {
    auto {}
  }
}

# retrieve from .tfvars which you do not git commit 
resource "google_secret_manager_secret_version" "db_user_version" {
  secret      = google_secret_manager_secret.db_user.id
  secret_data = var.wordpress_db_user
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.wordpress_db_password
}
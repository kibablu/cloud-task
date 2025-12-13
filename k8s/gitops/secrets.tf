# --- Postgres Credentials in Secret Manager ---
# 1. Generate a random password (optional, but good practice)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()"
}

# 2. Create the Secret
resource "google_secret_manager_secret" "postgres_creds" {
  secret_id = "postgres-chris-creds"
  labels = {
    env = "dev"
  }
  replication {
    auto {}
  }
}

# 3. Add the initial secret version (JSON format for easy parsing)
resource "google_secret_manager_secret_version" "postgres_creds_version" {
  secret = google_secret_manager_secret.postgres_creds.id
  secret_data = jsonencode({
    username = "chris_db_user"
    password = random_password.db_password.result
    database = "chris_db"
  })
}

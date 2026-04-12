# Generate a random password 
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()"
}

resource "google_secret_manager_secret" "postgres_creds" {
  secret_id = "SECRET_ID"
  labels = {
    env = "dev"
  }
  replication {
    auto {}
  }
}

# Add the initial secret version (JSON format for easy parsing)
resource "google_secret_manager_secret_version" "postgres_creds_version" {
  secret = google_secret_manager_secret.postgres_creds.id
  secret_data = jsonencode({
    username = "chris_db_user"
    password = random_password.db_password.result
    database = "chris_db"
  })
}

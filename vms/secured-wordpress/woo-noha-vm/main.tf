# 1.1 VPC Network
resource "google_compute_network" "wordpress_vpc" {
  name                    = "wordpress-vpc"
  auto_create_subnetworks = false
  description             = "VPC for WordPress application."
}

# 1.2 Subnet for Compute Engine (using a /26 CIDR block)
resource "google_compute_subnetwork" "wordpress_subnet" {
  name          = "wordpress-subnet"
  ip_cidr_range = "10.10.10.0/26" # Requested /26 CIDR
  region        = var.region
  network       = google_compute_network.wordpress_vpc.self_link
}

# -----------------------------------------------------------------------------
# 2. Firewall Rule (Allow 22, 80, 443 Ingress)
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "allow_web_ssh" {
  name    = "allow-wordpress-ingress"
  network = google_compute_network.wordpress_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"] # Requested ports
  }

  source_ranges = ["0.0.0.0/0"] # Allow from anywhere
  direction     = "INGRESS"
  target_tags   = ["wordpress-server"]
}

# -----------------------------------------------------------------------------
# 3. Service Account and IAM Roles (Cloud SQL & Cloud Storage & Secret Manager)
# -----------------------------------------------------------------------------

resource "google_service_account" "wordpress_sa" {
  account_id   = "wordpress-sa"
  display_name = "Service Account for WordPress Compute"
}

# IAM Role 1: Cloud SQL Client (allows connections/reads/writes to the database via Proxy)
resource "google_project_iam_member" "sql_client_role" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.wordpress_sa.email}"
}

# IAM Role 2: Storage Object Admin (allows read/write/delete objects in storage)
resource "google_project_iam_member" "storage_admin_role" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.wordpress_sa.email}"
}

# IAM Role 3: Secret Manager Accessor (allows VM to retrieve database credentials)
resource "google_secret_manager_secret_iam_member" "sa_secret_accessor" {
  secret_id = google_secret_manager_secret.wordpress_db_creds.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.wordpress_sa.email}"
}

# -----------------------------------------------------------------------------
# Secret Manager (Holds Cloud SQL Credentials)
# -----------------------------------------------------------------------------

# Randomly generate a secure password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()_+-="
}

# Create the Secret Manager resource to hold the password
resource "google_secret_manager_secret" "wordpress_db_creds" {
  secret_id = "wordpress-db-password"
  replication {
    auto {}
  }
}

# Create the first version of the secret with the generated password
resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.wordpress_db_creds.id
  secret_data = random_password.db_password.result
}

# -----------------------------------------------------------------------------
# 5. Cloud Storage Bucket (Publicly available)
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "wordpress_images" {
  name          = "${var.project_id}-wp-images-public" # Must be globally unique
  location      = var.region
  force_destroy = true

  # Ensure uniform access control to properly grant public access
  uniform_bucket_level_access = true
}

# Grant public read access to all objects in the bucket (roles/storage.objectViewer)
# This allows external users to read/download objects, but DOES NOT allow them to list 
# the contents of the entire bucket, thereby preventing general browsing.
resource "google_storage_bucket_iam_member" "public_object_reader" {
  bucket = google_storage_bucket.wordpress_images.name
  role   = "roles/storage.objectViewer"
  member = "allUsers" # Makes the contents publicly available for reading/viewing
}

# -----------------------------------------------------------------------------
# 6. HA Cloud SQL Instance (Sandbox Tier, Private IP Only)
# -----------------------------------------------------------------------------

# 6.1 RESERVE A SPECIFIC IP RANGE for Private Service Access
resource "google_compute_global_address" "private_ip_range" {
  name          = "cloud-sql-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL" # MUST be internal for VPC Peering
  prefix_length = 16         # Reserves the /16 block
  network       = google_compute_network.wordpress_vpc.id
}

# 6.2 Create Private Service Access Connection (VPC Peering)
resource "google_service_networking_connection" "vpc_service_connection" {
  network = google_compute_network.wordpress_vpc.id
  service = "servicenetworking.googleapis.com"
  # Reference the name of the newly defined allocated range
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# 6.3 Highly Available Cloud SQL Instance (MySQL, Sandbox tier/db-f1-micro, private IP)
resource "google_sql_database_instance" "wordpress_db" {
  database_version    = "MYSQL_8_0"
  project             = var.project_id
  region              = var.region
  deletion_protection = false
  settings {
    tier              = "db-g1-small" # Sandbox tier
    disk_type         = "PD_SSD"
    disk_size         = 10
    availability_type = "REGIONAL" # Enables High Availability (HA)

    backup_configuration {
      enabled            = true # Backups must be enabled for PITR
      binary_log_enabled = true # This enables PITR for MySQL
    }

    ip_configuration {
      ipv4_enabled    = false # Explicitly disables public IP
      private_network = google_compute_network.wordpress_vpc.id
    }
  }

  # Ensure the service networking connection is established before creating SQL
  depends_on = [google_service_networking_connection.vpc_service_connection]
}

# 6.4 Create the WordPress Database
resource "google_sql_database" "wordpress_db_name" {
  name     = "wordpress"
  instance = google_sql_database_instance.wordpress_db.name
}

# 6.5 Create the Database User using the Secret Manager password
resource "google_sql_user" "wordpress_user" {
  name     = "wp_user"
  instance = google_sql_database_instance.wordpress_db.name
  password = random_password.db_password.result
}

# -----------------------------------------------------------------------------
# 4. Compute Engine Instance (CentOS, Public IP, attached SA)
# -----------------------------------------------------------------------------

resource "google_compute_instance" "wordpress_vm" {
  name                = "wordpress-vm"
  machine_type        = "e2-medium"
  zone                = var.zone
  tags                = ["wordpress-server"]
  deletion_protection = false


  # Boot disk using CentOS (latest image)
  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-stream-9"
    }
  }

  # Network configuration
  network_interface {
    subnetwork = google_compute_subnetwork.wordpress_subnet.self_link

    # Access config for a public (external) IP address
    access_config {
      # Empty block requests an ephemeral public IP
    }
  }

  # Attach the Service Account (SA)
  service_account {
    email  = google_service_account.wordpress_sa.email
    scopes = ["cloud-platform"] # Full access scope to utilize SA roles
  }
}
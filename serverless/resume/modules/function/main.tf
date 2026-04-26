# Module: cloud_function
#
# Creates:
#   1. GCS bucket to store the function source zip
#   2. Zips function_src (excludes tests/ and dev files)
#   3. Grants required permissions to the two build service accounts
#   4. Dedicated runtime service account (least-privilege)
#   5. Cloud Functions Gen 2 function
#   6. IAM binding for unauthenticated HTTP invocations

locals {
  source_dir = "${path.root}/function_src"
  zip_path   = "${path.module}/function_src.zip"

  # Cloud Functions Gen 2 uses TWO service accounts during build:
  #
  # 1. Cloud Build SA  — <project-number>@cloudbuild.gserviceaccount.com
  #    Orchestrates the build pipeline.
  #
  # 2. Compute default SA — <project-number>-compute@developer.gserviceaccount.com
  #    Actually executes build steps (fetch source, build image, push to
  #    Artifact Registry). This is the one that needs roles/cloudbuild.builds.builder
  #    per https://cloud.google.com/functions/docs/troubleshooting#build-service-account

  cloudbuild_sa  = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  compute_sa     = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

# 1. Bucket for function source 
resource "google_storage_bucket" "function_src" {
  name                        = "${var.project_id}-fn-src-${var.name_prefix}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    condition { age = 30 }
    action    { type = "Delete" }
  }
}

# 2. Zip and upload function source (tests excluded) 
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = local.zip_path

  excludes = [
    "tests",
    "tests/__init__.py",
    "tests/test_visitor_counter.py",
    "requirements-dev.txt",
  ]
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "visitor-counter-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_src.name
  source = data.archive_file.function_zip.output_path
}

#  3a. Compute default SA — the actual build executor 
# GCP doc solution: grant roles/cloudbuild.builds.builder to the
# default Compute SA. This role bundles all permissions needed to
# fetch source, write logs, and push images to Artifact Registry.

resource "google_project_iam_member" "compute_sa_cloudbuild" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${local.compute_sa}"
}

# 3b. Cloud Build SA — the pipeline orchestrator 
# Needs log-writing permission so build output appears in Cloud Logging.

resource "google_project_iam_member" "cloudbuild_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

# 4. Custom Firestore role (true least privilege)
# roles/datastore.user is too broad — it includes delete, list,
# namespace and index permissions our function never uses.
# This custom role grants only the 4 permissions required to
# read and atomically update a single counter document.

resource "google_project_iam_custom_role" "firestore_counter" {
  role_id     = "cloudResumeFirestoreCounter"
  title       = "Cloud Resume — Firestore Counter"
  description = "Minimum permissions to read and increment the visitor counter document. No delete, no list, no index access."
  project     = var.project_id

  permissions = [
    "datastore.databases.get",          # connect to the database
    "datastore.entities.get",           # read the counter document
    "datastore.entities.create",        # create doc if it doesn't exist
    "datastore.entities.update",        # increment the counter (transactional write)
  ]
}

# 4. Dedicated runtime service account
# Separate from the build SA — this is what runs the function after deploy.
resource "google_service_account" "function_sa" {
  account_id   = "${var.name_prefix}-fn-sa"
  display_name = "Cloud Resume Function SA"
  project      = var.project_id
}

# Bind the custom role — not datastore.user
resource "google_project_iam_member" "firestore_counter" {
  project = var.project_id
  role    = google_project_iam_custom_role.firestore_counter.id
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# 5. Cloud Function Gen 2
resource "google_cloudfunctions2_function" "visitor_counter" {
  name     = "${var.name_prefix}-visitor-counter"
  project  = var.project_id
  location = var.region

  build_config {
    runtime     = "python312"
    entry_point = "visitor_counter"

    source {
      storage_source {
        bucket = google_storage_bucket.function_src.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    min_instance_count             = 0
    max_instance_count             = 10
    available_memory               = "256M"
    timeout_seconds                = 30
    service_account_email          = google_service_account.function_sa.email
    ingress_settings               = "ALLOW_INTERNAL_AND_GCLB"
    all_traffic_on_latest_revision = true

    environment_variables = {
      COLLECTION_NAME = var.collection_name
      DOCUMENT_ID     = var.document_id
      ALLOWED_ORIGIN  = var.allowed_origin
    }
  }

  labels = var.labels

  # Ensure IAM propagates before Cloud Build attempts the build
  depends_on = [
    google_project_iam_member.compute_sa_cloudbuild,
    google_project_iam_member.cloudbuild_sa_logging,
  ]
}

# 7. Public invoker (allUsers via LB only) 
# allUsers is required — resume visitors are anonymous.
# The ingress_settings = ALLOW_INTERNAL_AND_GCLB above means
# this only takes effect for requests arriving via the LB,
# not direct calls to the cloudfunctions.net URL.

resource "google_cloud_run_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.visitor_counter.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
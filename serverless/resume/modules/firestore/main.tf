# Module: firestore
#
# Creates:
#   1. Firestore database (Native mode)
#   2. Initial counter document via native Terraform resource
#      (no local-exec, no shell quoting issues)

resource "google_firestore_database" "resume" {
  project                     = var.project_id
  name                        = "(default)"
  location_id                 = var.location_id
  type                        = "FIRESTORE_NATIVE"
  delete_protection_state     = "DELETE_PROTECTION_DISABLED"
  deletion_policy             = "DELETE"

  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
}

# Seed the counter document 
# Uses the native Terraform resource — no shell, no gcloud, no
# quoting issues with the "(default)" database name.
#
# lifecycle.ignore_changes on fields means Terraform will create
# the document on first apply but will never reset the count back
# to 0 on subsequent applies (the real count is owned by the app).

resource "google_firestore_document" "counter" {
  project     = var.project_id
  database    = google_firestore_database.resume.name
  collection  = var.collection_name
  document_id = "counter"

  fields = jsonencode({
    count = { integerValue = "0" }
  })

  lifecycle {
    ignore_changes = [fields]
  }

  depends_on = [google_firestore_database.resume]
}
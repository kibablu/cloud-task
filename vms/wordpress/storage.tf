# Cloud Storage bucket (not public, but objects will be public)
resource "google_storage_bucket" "public_objects" {
  name                        = var.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  #description                 = "Storage bucket for WordPress media and assets"
}

# Allow all users to view objects (makes objects public, but not the bucket itself)
resource "google_storage_bucket_iam_member" "public_object_viewer" {
  bucket = google_storage_bucket.public_objects.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
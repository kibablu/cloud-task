# Module: storage
# Creates a private GCS bucket whose OBJECTS are publicly readable.
# The bucket itself is not publicly accessible via the Storage API
# (uniform bucket-level access is enforced, ACLs are disabled).
# Public read is granted at the object level via an IAM binding
# that allows allUsers to call storage.objects.get.

resource "google_storage_bucket" "resume" {
  name          = var.bucket_name
  project       = var.project_id
  location      = "US"           # multi-region for high availability + CDN edge caching
  storage_class = "STANDARD"

  # Uniform bucket-level access: disables legacy ACLs and enforces IAM only.
  # This is the recommended setting. Objects are still publicly readable
  # because of the IAM binding below.
  uniform_bucket_level_access = true

  # Serve index.html for directory requests and 404.html for missing objects
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # CORS: allow browsers to fetch assets from the resume domain
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type", "Cache-Control"]
    max_age_seconds = 3600
  }

  # Prevent accidental deletion via `terraform destroy`
  lifecycle {
    prevent_destroy = false   # set to true in production
  }

  labels = var.labels
}

# Public read on all objects 
# allUsers + roles/storage.objectViewer  →  every object is publicly
# readable via https://storage.googleapis.com/<bucket>/<object>
# The load balancer backend bucket uses this same mechanism.

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.resume.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

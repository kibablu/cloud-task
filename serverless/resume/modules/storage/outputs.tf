# Module: storage — Outputs

output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.resume.name
}

output "bucket_self_link" {
  description = "Self-link of the GCS bucket (used by the backend bucket resource)"
  value       = google_storage_bucket.resume.self_link
}

output "bucket_url" {
  description = "Base URL of the bucket"
  value       = google_storage_bucket.resume.url
}

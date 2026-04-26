output "function_url" {
  description = "HTTPS URL of the visitor counter Cloud Function"
  value       = google_cloudfunctions2_function.visitor_counter.service_config[0].uri
}

output "function_name" {
  description = "Cloud Function resource name"
  value       = google_cloudfunctions2_function.visitor_counter.name
}

output "service_account_email" {
  description = "Service account running the function"
  value       = google_service_account.function_sa.email
}

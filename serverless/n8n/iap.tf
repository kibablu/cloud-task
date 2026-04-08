# Block all unauthenticated access (Default behavior).
# Authorize IAP to invoke Cloud Run
# IAP uses its own system service account to 'talk' to your service.
resource "google_cloud_run_v2_service_iam_member" "iap_to_run_invoker" {
  location = google_cloud_run_v2_service.n8n.location
  name     = google_cloud_run_v2_service.n8n.name
  role     = "roles/run.invoker"
  
  # This specific service account is the 'bridge' for IAP traffic
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}

# Authorize YOUR Google Account to pass through the IAP Gate
# Even if someone knows the URL, they will be redirected to a Google Login.
# Only this email will be allowed through.
resource "google_iap_web_backend_service_iam_member" "user_access" {
  project             = data.google_project.project.project_id
  web_backend_service = google_compute_backend_service.n8n_backend.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "user:your_email@gmail.com" 
  depends_on = [google_compute_backend_service.n8n_backend]
}
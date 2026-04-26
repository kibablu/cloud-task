output "database_name" {
  value = google_firestore_database.resume.name
}

output "collection_name" {
  value = var.collection_name
}

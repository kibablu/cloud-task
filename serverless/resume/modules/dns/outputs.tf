# Module: dns — Outputs

output "name_servers" {
  description = "Name servers for the Cloud DNS zone. Point your domain registrar here if the zone was created by Terraform."
  value = var.create_zone ? google_dns_managed_zone.resume[0].name_servers : data.google_dns_managed_zone.existing[0].name_servers
}

output "a_record_name" {
  description = "FQDN of the A record created"
  value       = google_dns_record_set.resume_a.name
}

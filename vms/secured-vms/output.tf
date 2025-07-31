# Output the external IP addresses of the bastion and proxy hosts
output "bastion_external_ip" {
  description = "The external IP address of the bastion host"
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "proxy_external_ip" {
  description = "The external IP address of the proxy host"
  value       = google_compute_instance.proxy.network_interface[0].access_config[0].nat_ip
}

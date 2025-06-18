output "vm_name" {
  description = "Name of the created VM instance."
  value       = google_compute_instance.centos_vm.name
}

output "vm_external_ip" {
  description = "External IP address of the VM instance."
  value       = google_compute_instance.centos_vm.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM instance."
  value       = google_compute_instance.centos_vm.network_interface[0].network_ip
}

output "network_name" {
  description = "Name of the custom VPC network."
  value       = google_compute_network.custom_vpc.name
}

output "subnetwork_name" {
  description = "Name of the custom subnetwork."
  value       = google_compute_subnetwork.custom_subnet.name
}

output "zone_dns_name" {
  value       = google_dns_managed_zone.primary_zone.dns_name
  description = "The DNS name of the managed zone."
}

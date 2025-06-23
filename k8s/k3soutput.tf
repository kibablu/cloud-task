output "k3s_vpc_name" {
  description = "The name of the K3s VPC network."
  value       = google_compute_network.k3s_vpc.name
}

output "k3s_subnet_name" {
  description = "The name of the K3s subnet."
  value       = google_compute_subnetwork.k3s_subnet.name
}

output "k3_controlplane_details" {
  description = "Details of the K3s control plane node."
  value = {
    name         = google_compute_instance.k3_controlplane.name
    internal_ip  = google_compute_instance.k3_controlplane.network_interface[0].network_ip
    external_ip  = google_compute_instance.k3_controlplane.network_interface[0].access_config[0].nat_ip
    zone         = google_compute_instance.k3_controlplane.zone
  }
  sensitive = false 
}

output "k3_workernode_1_details" {
  description = "Details of the K3s worker node 1."
  value = {
    name         = google_compute_instance.k3_workernode_1.name
    internal_ip  = google_compute_instance.k3_workernode_1.network_interface[0].network_ip
    external_ip  = google_compute_instance.k3_workernode_1.network_interface[0].access_config[0].nat_ip
    zone         = google_compute_instance.k3_workernode_1.zone
  }
  sensitive = false
}

output "k3_workernode_2_details" {
  description = "Details of the K3s worker node 2."
  value = {
    name         = google_compute_instance.k3_workernode_2.name
    internal_ip  = google_compute_instance.k3_workernode_2.network_interface[0].network_ip
    external_ip  = google_compute_instance.k3_workernode_2.network_interface[0].access_config[0].nat_ip
    zone         = google_compute_instance.k3_workernode_2.zone
  }
  sensitive = false
}


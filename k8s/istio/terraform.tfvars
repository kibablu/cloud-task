project_id   = "PROJECT_ID_HERE"       # <-- replace with your actual project ID
region       = "us-central1"
zone         = "us-central1-a"
cluster_name = "bookinfo-istio"

# Networking
subnet_cidr   = "10.10.0.0/24"
pods_cidr     = "10.20.0.0/16"
services_cidr = "10.30.0.0/16"
master_cidr   = "172.16.0.0/28"

# Restrict to your workstation/CI IP in production e.g. "203.0.113.10/32"
authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "all"
  }
]

# Node pool
machine_type   = "e2-standard-4"
node_count     = 3
node_min_count = 2
node_max_count = 6
disk_size_gb   = 50

labels = {
  app        = "bookinfo"
  managed-by = "terraform"
}
<p align="center">
  <a href="https://www.terraform.io/">
    <img src="https://img.shields.io/badge/Terraform-7B42BC.svg?style=for-the-badge&logo=Terraform&logoColor=white" alt="Terraform">
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <!-- TODO: Update the git_repo URL to point to your repository -->
  <a href="https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/kibablu/cloud-task/tree/main/k8s/gke/README.md">
    <img src="https://gstatic.com/cloudssh/images/open-btn.svg" alt="Open in Cloud Shell">
  </a>
</p>

This repository contains Terraform code to provision a secure, multi-cluster Google Kubernetes Engine (GKE) environment on Google Cloud Platform (GCP). The infrastructure is designed with security, separation of concerns, and cost-effectiveness in mind, making it a solid foundation for deploying containerized applications.

## Project Goal

The primary objective is to automate the creation of a production-ready GKE setup that includes:
- A custom Virtual Private Cloud (VPC) network.
- Three distinct, private GKE clusters for different environments (`app`, `db`, `ops`).
- Secure access patterns using a bastion host.
- Cost-optimized node pools using Spot VMs.
- Modern GKE features like Dataplane V2, Workload Identity, and Cloud DNS.

## Architecture Overview

The Terraform configuration will create the following resources:

### 1. Networking
- **Custom VPC**: A dedicated VPC (`-gke-vpc`) is created to isolate the environment, with subnetwork creation set to manual for granular control.
- **Subnets**:
  - Three primary subnets (`app`, `db`, `ops`), each with dedicated secondary IP ranges for GKE Pods and Services.
  - A separate, smaller subnet for a bastion/jump host.
- **Cloud NAT**: A Cloud NAT gateway is configured to allow instances in the private subnets (like GKE nodes) to access the internet for outbound traffic (e.g., pulling container images) without needing public IP addresses.
- **Firewall Rules**:
  - An `allow-internal` rule permits all traffic within the VPC.
  - An `allow-ssh-to-bastion` rule allows SSH access to the bastion host from the internet. **Note: This is currently open to `0.0.0.0/0` and should be restricted to specific IP addresses in a production environment.**
- **Static IP**: A static external IP address is reserved for the application load balancer.

### 2. GKE Clusters
- **Three Private Clusters**: The configuration deploys three separate GKE clusters (`gke-app-cluster`, `gke-db-cluster`, `gke-ops-cluster`), each residing in its own subnet.
- **Private by Default**: Clusters are configured as private, meaning nodes do not have public IP addresses. The control plane has a private endpoint accessible only from within the VPC.
- **Authorized Networks**: The control plane is only accessible from the cluster's own subnet and the bastion host's subnet.

### 3. Compute & Node Pools
- **Bastion Host**: A small `e2-small` VM instance is created to serve as a secure jump host for `kubectl` access to the private GKE clusters.
- **Custom Node Pools**: Each cluster has a dedicated node pool.
  - **Machine Type**: Nodes use cost-effective `e2-medium` machine types.
  - **Spot VMs**: Node pools are configured to use Spot VMs to significantly reduce costs, suitable for fault-tolerant workloads.

### 4. Security & IAM
- **Dedicated Service Account**: A custom IAM Service Account (`gke-node-sa`) is created for the GKE nodes.
- **Least Privilege**: This service account is granted the `roles/secretmanager.secretAccessor` role, allowing nodes to securely access secrets stored in Google Secret Manager.
- **Workload Identity**: Enabled on all clusters to provide a secure, recommended way for GKE workloads to access Google Cloud services.
- **Shielded GKE Nodes**: Enabled on the node pools to provide verifiable integrity of the node instances.
- **Security Posture**: GKE's basic security posture scanning is enabled to detect common security misconfigurations.

## Key Features Implemented

- **Dataplane V2**: Uses the advanced CNI for improved networking performance and security.
- **Cloud DNS for GKE**: Integrates cluster DNS with Cloud DNS for seamless, VPC-wide service discovery.
- **Persistent Storage**: The GCE Persistent Disk CSI Driver is enabled, allowing stateful workloads to use persistent disks.
- **HTTP Load Balancing**: The addon is enabled for the `app` cluster to facilitate ingress and load balancing for web applications.
- **Optimized Observability**: Default logging and monitoring components are disabled, allowing for a custom or more cost-effective observability stack to be implemented separately.

## How to Use

### Prerequisites
1. Terraform (version >= 1.5.7) installed.
2. Google Cloud SDK (`gcloud`) installed and configured.
3. A GCP project with the necessary APIs enabled (Terraform will handle enabling them).
4. Authenticated to GCP with appropriate permissions to create the resources.
   ```bash
   gcloud auth application-default login
   ```

### Configuration
1. **Clone the repository.**
2. **Update Project ID**: Modify the `default` value for the `gcp_project_id` variable in `vars.tf` to your own GCP Project ID.
   ```terraform
   # /home/kibablu16/gke/vars.tf
   variable "gcp_project_id" {
     description = "The ID of the GCP project where resources will be created"
     type        = string
     default     = "your-gcp-project-id" # <-- CHANGE THIS
   }
   ```
3. **(Optional)** Create a `terraform.tfvars` file to override other variables without modifying the `vars.tf` file.

### Deployment
1. **Initialize Terraform**:
   ```bash
   terraform init
   ```
2. **Plan the deployment**:
   ```bash
   terraform plan
   ```
3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## References

1. [Enable the Secret Manager CSI component](https://cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component#secretmanager-addon-enable-console)
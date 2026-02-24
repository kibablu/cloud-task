
![otel](https://github.com/user-attachments/assets/580866b1-1a13-4619-8f79-fe43359cc4da)

# Provision a GKE Cluster for the OpenTelemetry Demo with Custom DNS

This Terraform project provisions a Google Kubernetes Engine (GKE) cluster on Google Cloud Platform (GCP), complete with the necessary networking, firewall rules, and DNS configuration to run the OpenTelemetry (OTel) Demo.

It sets up a custom domain with a public DNS zone and a managed SSL certificate, allowing you to access the OTel demo via a secure, public-facing URL instead of `localhost`.

## Features

- **VPC Native GKE Cluster**: Creates a GKE cluster within a custom Virtual Private Cloud (VPC).
- **Separate Subnets**: Uses distinct subnets for the GKE cluster and other VMs (like a bastion host).
- **Custom DNS Configuration**: Sets up a Cloud DNS managed zone and an 'A' record for your custom domain.
- **Managed SSL**: Provisions a Google-managed SSL certificate for your domain to enable HTTPS.
- **Bastion Host Ready**: Includes firewall rules and a service account for a bastion host to securely access the cluster.

## Prerequisites

Before you begin, ensure you have the following:

1.  **Google Cloud Project**: A GCP project with billing enabled.
2.  **Registered Domain Name**: You must own a public domain name that you can manage.
3.  **Required Permissions**: Your GCP user or service account must have sufficient permissions to create the resources defined in this project (e.g., `Project Owner`, `Editor`, or a custom role with Compute Engine, GKE, and DNS admin rights).
4.  **Terraform**: Terraform installed on your local machine.
5.  **Google Cloud SDK**: The `gcloud` command-line tool installed and authenticated.

## Configuration

1.  **Clone the repository** (if you haven't already).

2.  **Update Terraform Variables**:
    Open the `variables.tf` file and modify the default values for the following variables:

    -   `project_id`: Your Google Cloud project ID.
    -   `domain_name`: Your registered public domain (e.g., `my-otel-demo.com`).

    ```terraform
    variable "project_id" {
      description = "The GCP project ID to deploy resources into"
      type        = string
      default     = "your-gcp-project-id" // <-- UPDATE THIS
    }

    variable "domain_name" {
      description = "The public domain name for your Cloud DNS zone (e.g., chrisproject.org)"
      type        = string
      default     = "your-domain.com" // <-- UPDATE THIS
    }
    ```

## Deployment

Follow these steps to provision the infrastructure:

1.  **Initialize Terraform**:
    Open your terminal in the `otel` directory and run:
    ```sh
    terraform init
    ```

2.  **Review the Plan**:
    Check the resources that Terraform will create:
    ```sh
    terraform plan
    ```

3.  **Apply the Configuration**:
    Deploy the resources to your GCP project. Confirm with `yes` when prompted.
    ```sh
    terraform apply
    ```

## Post-Deployment Steps

### 1. Update Your Domain's Name Servers

After `terraform apply` completes, Terraform will output the name servers for your new Cloud DNS zone. You need to update the name server records at your domain registrar (e.g., GoDaddy, Namecheap, Google Domains) to point to these values.

Example output:
```
Outputs:

name_servers = [
  "ns-cloud-e1.googledomains.com.",
  "ns-cloud-e2.googledomains.com.",
  "ns-cloud-e3.googledomains.com.",
  "ns-cloud-e4.googledomains.com.",
]
```

### 2. Install the OpenTelemetry Demo

With the infrastructure ready, you can now deploy the OpenTelemetry Demo to your GKE cluster. You will need to configure an Ingress resource to use the static IP and managed certificate created by Terraform.

Refer to the official OpenTelemetry Demo documentation for instructions on deploying to Kubernetes. When configuring your Ingress, ensure it references the static IP and the Google-managed SSL certificate.

## Cleanup

To avoid incurring ongoing charges, destroy the resources when you are finished:

```sh
terraform destroy
```


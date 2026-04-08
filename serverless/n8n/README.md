![wikipedia](https://github.com/user-attachments/assets/ec5095db-840f-45df-98f1-608c8e2fe63d)

# n8n Serverless Infrastructure on Google Cloud

![n8n](https://img.shields.io/badge/n8n-FF6D5A?style=for-the-badge&logo=n8n&logoColor=white)
![Google Cloud](https://img.shields.io/badge/GoogleCloud-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Cloud Build](https://img.shields.io/badge/Cloud_Build-1a73e8?style=for-the-badge&logo=googlecloud&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)

This Terraform module provisions a secure, highly-available, and serverless workflow automation environment utilizing [n8n](https://n8n.io/) on Google Cloud Platform (GCP).

## 🏗️ Architecture Overview

This infrastructure is designed for enterprise-grade automation, emphasizing minimal operational overhead, strict security bounds, and seamless scalability.

- **Compute (Serverless):** n8n is deployed via **Google Cloud Run**, automatically scaling out to handle workflow spikes and scaling down to save costs. 
- **Database:** State and execution data are persistently stored in a **Cloud SQL (PostgreSQL 15)** Enterprise instance.
- **Networking & Security:** 
  - Protected by **Identity-Aware Proxy (IAP)** to enforce Zero-Trust access to the n8n dashboard.
  - **Serverless VPC Access Connectors** bridge the serverless environment with a private Virtual Machine (hosting Ollama/DeepSeek AI models and internal MCP services).
- **CI/CD:** Pre-configured IAM roles support **Google Cloud Build** and **Artifact Registry** for seamless container image delivery.
- **DNS:** Automatic domain management utilizing **Cloud DNS**.
- **Observability:** Built-in **Cloud Monitoring** with proactive alerting for memory utilization and container scaling thresholds.

## 📂 Module Structure

| File | Description |
|------|-------------|
| `n8n.tf` | Cloud Run service configuration for n8n, handling environment variables, scaling limits, and liveness probes. |
| `postgres.tf` | Cloud SQL instance and database configuration, including randomized secure passwords and connection tuning. |
| `iam.tf` | Granular Identity and Access Management policies (least privilege) for Cloud Run, Cloud Build, and IAP. |
| `dns.tf` | Managed DNS zone and A-records linking your custom domain to the global load balancer. |
| `monitoring.tf` | Alert policies and notification channels for monitoring DB memory usage and Cloud Run scaling bottlenecks. |
| `vars.tf` | Input variables to make the module easily reusable (Project ID, Region, Domain Name, IAP Secrets). |
| `output.tf` | Critical outputs required post-deployment (URLs, DNS Name Servers, SSH commands for the private VM). |

## 🚀 Quick Start

Ensure you have authenticated with GCP using `gcloud auth application-default login` and have initialized Terraform.

1. Provide the required variables in a `terraform.tfvars` file (or pass them via CLI):
   ```hcl
   project_id        = "your-gcp-project-id"
   domain_name       = "your-domain.com"
   iap_client_id     = "your-oauth-client-id"
   iap_client_secret = "your-oauth-client-secret"
   ```
2. Plan the deployment:
   ```bash
   terraform plan
   ```
3. Apply the infrastructure:
   ```bash
   terraform apply
   ```

## 📝 Post-Deployment Steps

1. **DNS Delegation:** Check the `dns_name_servers` output and update your domain registrar (GoDaddy, Namecheap, etc.) to point to Google Cloud DNS.
2. **IAP Access:** Ensure your Google Account has the "IAP-secured Web App User" role to bypass the Zero-Trust screen and access the n8n editor.
3. **Connecting to Internal VM:** Use the `vm_ssh_command` output to securely SSH into your internal AI/MCP VM via IAP tunneling without exposing it to the public internet.

---

*Built with modern Cloud Native principles for scalable automation.*

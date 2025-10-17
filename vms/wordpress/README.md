# WordPress on GCP: Highly Available & Secure with Terraform

![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?style=for-the-badge&logo=Terraform&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google%20Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)

This project deploys a highly available, scalable, and secure WordPress environment on Google Cloud Platform (GCP). The architecture utilizes an External Global HTTPS Load Balancer to efficiently distribute traffic worldwide across a Managed Instance Group (MIG) running CentOS/RHEL.

---

## 🔒 Security & Connectivity Highlights

This solution is designed for maximum security and minimal public exposure:

-   **Zero Public IP**: The WordPress instances within the Managed Instance Group (MIG) do not have public IP addresses. All incoming traffic is routed exclusively through the Global Load Balancer.

-   **Secret Manager**: Database credentials (user and password) are securely managed and retrieved at runtime using the GCP Secret Manager, ensuring credentials are never stored in plaintext within configuration files or the startup script.

-   **Private Database**: The Cloud SQL database is only accessible via Private Service Access and the secure Cloud SQL Proxy running on the application instances.

---

## 🚀 Architecture Overview

| Component | GCP Service | Configuration |
| :--- | :--- | :--- |
| **Frontend** | Global HTTPS Load Balancer | Global traffic routing, DDoS protection, and external SSL termination on a static IP. |
| **Backend** | Managed Instance Group (MIG) | Provides auto-scaling and auto-healing for 3 Apache/WordPress instances (private IP only). |
| **Secrets** | Secret Manager | Stores `wordpress-db-user` and `wordpress-db-password`. |
| **Database** | Cloud SQL (MySQL) | Highly available, private database instance. |
| **Connectivity** | Cloud SQL Proxy (in startup script) | Securely connects the private WordPress instance to the private Cloud SQL instance over an internal tunnel. |

---

## 🎯 Crucial Problem Solving & Fixes Implemented

This deployment required specific, low-level fixes integrated into the startup script and Terraform configuration:

### 1. Global LB Health Check Stability

> **Fix**: The Health Check path was changed to a static file (`/health.txt`) to bypass potential application crashes that occurred when the Load Balancer probed the dynamic WordPress application root (`/`). This ensures the backends consistently register as **Healthy**.

-   **Terraform Change**: `request_path = "/health.txt"`
-   **Startup Script Change**: File creation via `echo 'OK' > /var/www/html/health.txt`.

### 2. HTTPS Redirect Loop Prevention

> **Fix**: When the Global LB terminates SSL, traffic arrives at the backend instance via HTTP, causing WordPress to redirect infinitely. We injected PHP code into `wp-config.php` to correctly read the `X-Forwarded-Proto` header, forcing WordPress to recognize the request as HTTPS.

-   **Solution**: Uses Terraform domain variables (e.g., `${wp_domain}`) to set canonical URLs (`WP_HOME`/`WP_SITEURL`) and injects critical PHP logic for header recognition within the startup script.

### 3. Instance Hardening (Firewall & SELinux)

> **Firewall/SELinux**: `firewalld` was configured to allow port `443`, and the SELinux boolean `httpd_can_network_connect` was enabled to allow the Apache web server to connect to the network (specifically the Cloud SQL Proxy).

---

## ⚙️ Deployment Instructions (Terraform)

### Prerequisites

-   A GCP project with the necessary APIs enabled (Compute Engine, Cloud SQL, Secret Manager).
-   Terraform CLI installed and authenticated (`gcloud auth application-default login`).
-   A custom CentOS/RHEL image with Apache/PHP installed, referenced by `var.custom_image`.
-   Database credentials stored in GCP Secret Manager.

### 1. Initialize and Deploy

Initialize Terraform to download the necessary providers.
```sh
# Initialize Terraform
terraform init
```

Review and apply the configuration. You will need to provide values for your domain.
```sh
# Review and apply the configuration
terraform apply \
  -var="wp_domain=example.com" \
  -var="wp_www_domain=www.example.top"
```

### 2. Post-Deployment & DNS

Retrieve the static IP address of the Global Load Balancer from the Terraform output:

```sh
terraform output lb_static_ip
```

**Update DNS**: Configure `A` records with your domain registrar to point your domain and `www` subdomain to this static IP.

---

## 📚 Additional Resources & References

-   [Configuring Private Services Access](https://cloud.google.com/vpc/docs/configure-private-services-access#removing-connection)
-   [Using Google-managed SSL certificates with Terraform](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#terraform_1)
-   [Enabling IAP for GCE & GKE](https://cloud.google.com/iap/docs/load-balancer-howto#enable-iap)
-   [CodeLab: Connect to Cloud SQL from GCE (Private IP)](https://codelabs.developers.google.com/codelabs/cloud-sql-connectivity-gce-private#3)

---

## 🗑️ Cleanup and Destruction

To safely tear down all components created by this project:

> **⚠️ WARNING**: This command destroys all managed resources, including the database (if not protected by lifecycle rules or `deletion_protection`).

```sh
terraform destroy
```

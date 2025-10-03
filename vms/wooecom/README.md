# 🚀 Automated WordPress Deployment on GCP VM

This repository contains a robust Bash startup script to automate the deployment of a secure, production-ready WordPress instance on a Google Cloud Platform (GCP) Virtual Machine.  
It leverages Google Cloud SQL, Secret Manager, Cloud SQL Auth Proxy, and SELinux for a cloud-native LAMP stack.

---

## 📝 Features

- **Automated LAMP Stack Setup:** Installs Apache, PHP, and necessary dependencies.
- **Secure Database Connection:** Uses Cloud SQL Auth Proxy and Secret Manager to securely connect to a managed MySQL instance.
- **Dynamic WordPress Configuration:** Downloads, unpacks, and configures WordPress with credentials fetched at runtime.
- **Security Hardened:** SELinux and firewall rules are applied for secure HTTPD operation and database communication.
- **One-Click Custom Image Creation:** Wrap up your deployed VM as a custom image for scalable deployments.

---

## ⚡ Quick Start

1. **Update Configuration Variables**  
   Edit any variables as needed at the top of the script:
   ```bash
   DB_NAME="your-db-name"
   DB_USER="your-db-user"
   DB_SECRET_ID="your-db-secretID"
   DB_CONNECTION_NAME="your-connection-string"
   PROJECT_ID="your-gcp-project-id"
   ```
   > These should match your Cloud SQL and Secret Manager setup.

2. **Run the Script**  
   SSH into your GCP VM and execute:
   ```bash
   chmod +x setup-wordpress.sh
   ./setup-wordpress.sh
   ```

3. **Verify WordPress**  
   - Navigate to your VM's external IP in a browser.
   - Complete the final setup in the WordPress web installer.

4. **Create a Custom Image (Optional)**  
   After setup, create a reusable VM image:
   ```bash
   gcloud compute images create wordpress-custom-image-final \
     --project=YOUR_PROJECT_ID \
     --family=wordpress-mig-template \
     --source-disk=YOUR_DISK_NAME \
     --source-disk-zone=YOUR_DISK_ZONE \
     --storage-location=YOUR_REGION
   ```

---

## 🔒 Security Considerations

- **Passwords are never hardcoded:** Pulled from Secret Manager at runtime.
- **No credential files:** Uses Application Default Credentials via VM's service account.
- **SELinux enforced:** Ensures Apache can connect to the Cloud SQL Proxy securely.

---

## 📋 Script Overview

- Installs core packages and Google Cloud SDK
- Installs and runs Cloud SQL Auth Proxy
- Fetches DB credentials securely using `gcloud secrets`
- Downloads and configures WordPress
- Sets permissions and configures SELinux and firewall
- Starts Apache web server

---

## 🛠️ Prerequisites

- GCP Project with billing enabled
- Cloud SQL instance and Secret Manager secret created
- VM with sufficient permissions to access Secret Manager and Cloud SQL
- (Optional) Google Cloud SDK installed locally for image creation

---

## 🎯 References

- [Google Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/mysql/connect-auth-proxy)
- [WordPress on Compute Engine](https://cloud.google.com/compute/docs/tutorials/wordpress-deployment-manager)
- [Google Secret Manager](https://cloud.google.com/secret-manager)
- [Configure Private Services Access with Terraform](https://cloud.google.com/vpc/docs/configure-private-services-access#terraform)
- [Removing a Private Services Access Connection](https://cloud.google.com/vpc/docs/configure-private-services-access#removing-connection)
- [Cloud SQL Connectivity via GCE and Private IP (Codelab)](https://codelabs.developers.google.com/codelabs/cloud-sql-connectivity-gce-private#3)

---

**Happy deploying your cloud-native WordPress!**
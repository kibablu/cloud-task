
<img width="1103" height="658" alt="erp" src="https://github.com/user-attachments/assets/aaaf3203-b943-4047-850c-b85646355b7b" />

# ERPNext + Coolify: Deployment Magic on Google Cloud

This project demonstrates a production-ready deployment of ERPNext v15 on Google Compute Engine using Coolify as a self-hosted PaaS. By leveraging Docker containerization and automated proxy management, we've created a scalable and easily maintainable ERP environment.

## 🚀 Overview

* Platform: Google Cloud Platform (GCP)

* Orchestration: Coolify (Docker Compose)

* Architecture: Multi-container (Nginx, Gunicorn, MariaDB, Redis, Workers)

* SSL/TLS: Automated via Let's Encrypt (Coolify Proxy)

## 🏗 Infrastructure Setup

1. Google Compute Engine (GCE)
    * Machine Type: e2-medium (2 vCPU, 4GB RAM recommended minimum)

    * OS: Ubuntu 22.04 LTS

    * Firewall Rules: Allow TCP `80`, `443` (Web traffic)

    * Allow TCP `8080` (Internal Nginx ingress)

    * Allow TCP `8000` (Initial Coolify setup - disabled after domain mapping)

2. DNS Configuration
Managed via Google Cloud DNS using a Wildcard strategy:

    * *.klaudmazoezi.top -> VM_PUBLIC_IP (Catch-all for sites)

    * klaudmazoezi.top -> VM_PUBLIC_IP (Coolify Dashboard)

## 🛠 Deployment Steps

* Step 1: Install Coolify
On your GCE instance, run:

```
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

Access the dashboard at http://your-ip:8000 and map your domain.

* Step 2: Docker Compose Configuration

    Create a new Docker Compose resource in Coolify. Key environment variables used:

    * `FRAPPE_SITE_NAME_HEADER`: `$$host` (Crucial for Nginx routing)

    * `UPSTREAM_REAL_IP_ADDRESS`: `127.0.0.1` (Or proxy IP)

    * `DB_PASSWORD`: Your secure MariaDB password

* Step 3: Site Initialization

Access the frappe-backend terminal via Coolify and run:


## Create the site

```
bench new-site erpnext.klaudmazoezi.top \
  --admin-password "admin_password" \
  --mariadb-root-password "root_password"


# Install the ERPNext app

bench --site erpnext.klaudmazoezi.top install-app erpnext

# Set as default

bench use erpnext.klaudmazoezi.top
```

## ⚠️ Troubleshooting & Lessons Learned

**Nginx "Service Unavailable" / 404**

If the site is not found despite containers being healthy, verify that the `FRAPPE_SITE_NAME_HEADER` is set to `$$host`. This ensures Nginx uses the domain name to look up the site directory in the shared `sites` volume.

**MariaDB OperationalError (1045)**

If you encounter access denied errors, manually sync the database user:

```
ALTER USER 'site_user_name'@'%' IDENTIFIED BY 'password_from_site_config';
FLUSH PRIVILEGES;
```

**Enable Background Jobs**
Don't forget to enable the scheduler to allow the ERP to process automated tasks:

```
bench --site erpnext.klaudmazoezi.top enable-scheduler
```

## 📜 License
This project is shared for educational purposes. ERPNext is licensed under GNU GPL v3

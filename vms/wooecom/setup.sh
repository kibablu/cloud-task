#!/bin/bash
set -e # Exit immediately if any command returns a non-zero status.

# ====================================================================
# REQUIRED MANUAL SETUP
# ====================================================================
# This section uses hardcoded values based on your last Terraform output.
# --------------------------------------------------------------------

# 3. Define configuration variables (VALUES ALREADY SET)
DB_NAME="your-db-name"
DB_USER="your-db-user"
DB_SECRET_ID="your-db-secretID"
DB_CONNECTION_NAME="your-connection-string"
PROJECT_ID="your-project-ID"

# ====================================================================
# INSTALLATION START
# ====================================================================

echo "STARTUP SCRIPT DEBUG: Starting execution..."

# 1. Install LAMP stack components and dependencies
sudo yum clean all
sudo yum update -y
# Install EPEL repository for modern PHP and other tools
sudo yum install -y epel-release

echo "STARTUP SCRIPT DEBUG: Installing Core Packages (httpd, php, sql client)..."
sudo yum install -y httpd php php-mysqlnd php-gd php-xml php-mbstring wget policycoreutils-python

# Install Google Cloud SDK for Secret Manager access
echo "STARTUP SCRIPT DEBUG: Installing Google Cloud SDK..."
# FIX: Added 'sudo' to tee to write to the /etc directory
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo <<EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.com/yum/doc/rpm-package-key.gpg
EOM
sudo yum install -y google-cloud-sdk

# 2. Install Cloud SQL Auth Proxy
echo "STARTUP SCRIPT DEBUG: Installing Cloud SQL Auth Proxy..."
# FIX: Added 'sudo' because the destination is a root-owned directory (/usr/local/bin)
sudo wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /usr/local/bin/cloud_sql_proxy
sudo chmod +x /usr/local/bin/cloud_sql_proxy

# 4. Fetch the secure password from Secret Manager
echo "STARTUP SCRIPT DEBUG: Retrieving DB password from Secret Manager..."
# Uses gcloud to fetch the latest version of the secret and decodes it
DB_PASSWORD=$(gcloud secrets versions access latest --secret="$DB_SECRET_ID" --project="$PROJECT_ID" --format='get(payload.data)' | base64 -d)

# 5. Start the Cloud SQL Auth Proxy in the background
# NOTE: The proxy itself does not require sudo, but the rest of the script does.
echo "STARTUP SCRIPT DEBUG: Starting Cloud SQL Auth Proxy..."
# FIX: Removed -credential_file flag to rely on the VM's attached Service Account (Application Default Credentials)
/usr/local/bin/cloud_sql_proxy -instances="$DB_CONNECTION_NAME"=tcp:3306 &

# Wait a moment for the proxy to start
sleep 5

# 6. Download and configure WordPress
echo "STARTUP SCRIPT DEBUG: Downloading and configuring WordPress..."
cd /tmp
sudo wget -q https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz

# FIX: Explicitly create the /var/www/html directory before copying files
sudo mkdir -p /var/www/html/ 

# FIX: Added 'sudo' for copying files into the /var/www/html directory
sudo cp -R wordpress/* /var/www/html/

# Create wp-config.php content dynamically using the retrieved password
# FIX: Added 'sudo' to cat/redirect to write to the protected directory
sudo cat <<EOT > /var/www/html/wp-config.php
<?php
define( 'DB_NAME', '$DB_NAME' );
define( 'DB_USER', '$DB_USER' );
define( 'DB_PASSWORD', '$DB_PASSWORD' );
define( 'DB_HOST', '127.0.0.1:3306' ); // Connects to the local Cloud SQL Auth Proxy endpoint
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

// Unique security keys (placeholder values)
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

\$table_prefix = 'wp_';
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
// Add configuration for Cloud Storage integration here if needed later
?>
EOT

# 7. Set permissions and start services
echo "STARTUP SCRIPT DEBUG: Setting permissions and starting services..."

# === CRITICAL FIXES FOR DB CONNECTION ===

# FIX 1: Allow httpd (PHP) to make outgoing network connections (REQUIRED for Cloud SQL Proxy)
echo "STARTUP SCRIPT DEBUG: Fixing SELinux boolean for HTTPD network access..."
sudo setsebool -P httpd_can_network_connect on

# FIX 2: Ensure FirewallD isn't blocking local traffic (shouldn't be, but good check)
echo "STARTUP SCRIPT DEBUG: Ensuring Firewalld doesn't block local loopback..."
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent || true
sudo firewall-cmd --reload || true
# ========================================

# FIX: Added 'sudo' to chown and chcon for permission changes
sudo chown -R apache:apache /var/www/html

# SELinux context fixes for web content and writeable uploads
sudo chcon -R -t httpd_sys_content_t /var/www/html
sudo chcon -t httpd_sys_rw_content_t /var/www/html/wp-content

# FIX: Added 'sudo' to systemctl commands
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl enable php-fpm

echo "STARTUP SCRIPT DEBUG: WordPress setup complete."

# Create a custom image for later user as a HA MIG
gcloud compute images create wordpress-custom-image-final \
--project=ecommerce-471903 \
--family=wordpress-mig-template \
--source-disk=wordpress-vm \ 
--source-disk-zone=us-central1-a \
--storage-location=us-central1
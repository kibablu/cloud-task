#!/bin/bash
set -e

WORDPRESS_ROOT="/var/www/html" 
WP_CONFIG_PATH="$${WORDPRESS_ROOT}/wp-config.php"

# Install Cloud SQL Proxy
CLOUD_SQL_PROXY_VERSION=1.37.4

wget -q "https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64" -O /usr/local/bin/cloud_sql_proxy
chmod +x /usr/local/bin/cloud_sql_proxy

# ----------------------------------------------------------------------
#  Install gcloud SDK using yum/dnf for CentOS/RHEL 
# ----------------------------------------------------------------------
if ! command -v gcloud &> /dev/null; then
  echo "Installing Google Cloud SDK for CentOS/RHEL..."
  
  # Add the Google Cloud SDK repository configuration
  tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.com/yum/doc/rpm-package-key.gpg
EOM

  # Install the SDK (using 'yum' which works on older and current CentOS versions)
  yum install -y google-cloud-sdk
fi
# ----------------------------------------------------------------------

# Fetch WordPress DB user and password from Secret Manager
DB_USER=$(gcloud secrets versions access latest --secret=wordpress-db-user 2>/dev/null)
DB_PASS=$(gcloud secrets versions access latest --secret=wordpress-db-password 2>/dev/null)

# Export as environment variables for WordPress (variables are correctly escaped for Terraform)
echo "export WORDPRESS_DB_USER='$${DB_USER}'" >> /etc/profile.d/wordpress_env.sh
echo "export WORDPRESS_DB_PASSWORD='$${DB_PASS}'" >> /etc/profile.d/wordpress_env.sh

# Cloud SQL instance connection name (now using a Terraform template variable 'connection_name')
INSTANCE_CONNECTION_NAME="${connection_name}"

# --- 4. Install mod_ssl and OpenSSL ---

echo "Installing mod_ssl for Apache HTTPS support..."
yum install -y mod_ssl openssl

# --- 5. Generate Self-Signed Certificate for Health Check ---

echo "Generating self-signed SSL certificate..."
sudo mkdir -p /etc/pki/tls/certs /etc/pki/tls/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/pki/tls/private/apache-selfsigned.key \
    -out /etc/pki/tls/certs/apache-selfsigned.crt \
    -subj "/C=US/ST=CA/L=SF/O=GCP/CN=localhost"


# --- 6. Configure Apache (httpd.conf and ssl.conf) ---

echo "Configuring Apache to use SSL on port 443..."

# The mod_ssl install created /etc/httpd/conf.d/ssl.conf, which already has "Listen 443 https"
# We need to ensure that the settings within ssl.conf point to our generated certificate.

# Use sed to replace the default cert/key paths in the newly installed ssl.conf
sudo sed -i 's|^SSLCertificateFile .*$|SSLCertificateFile /etc/pki/tls/certs/apache-selfsigned.crt|' /etc/httpd/conf.d/ssl.conf
sudo sed -i 's|^SSLCertificateKeyFile .*$|SSLCertificateKeyFile /etc/pki/tls/private/apache-selfsigned.key|' /etc/httpd/conf.d/ssl.conf


# --- 7. Configure Firewall and SELinux ---

echo "Configuring firewalld and SELinux to allow HTTPS..."

# Allow HTTPS (port 443) through firewalld
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

# Allow httpd to access network ports (like 443) which might be restricted by SELinux
setsebool -P httpd_can_network_connect 1

# ----------------------------------------------------------------------
# SYSTEMD SERVICE SETUP (Correct for CentOS) 
# ----------------------------------------------------------------------
if [ -z "$INSTANCE_CONNECTION_NAME" ]; then
  echo "WARNING: Cloud SQL Connection Name not set. Cloud SQL Proxy will not be started."
else
  echo "Setting up Cloud SQL Proxy as a systemd service..."

  # Create the systemd unit file
  cat <<EOF > /etc/systemd/system/cloudsql-proxy.service
[Unit]
Description=Cloud SQL Proxy for Cloud SQL
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root

# The connection string uses the template variable passed by Terraform
ExecStart=/usr/local/bin/cloud_sql_proxy -instances=${connection_name}=tcp:3306
Restart=always
Type=simple

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd configuration
  systemctl daemon-reload

  # Enable the service to ensure it starts on future boots
  systemctl enable cloudsql-proxy.service

  # Start the service immediately
  systemctl start cloudsql-proxy.service
fi

# ----------------------------------------------------------------------
#  Health Check File and WordPress HTTPS 
# ----------------------------------------------------------------------
echo "Creating static health check file at $${WORDPRESS_ROOT}/health.txt..."
sudo sh -c "echo 'OK' > $${WORDPRESS_ROOT}/health.txt"
sudo chmod 644 $${WORDPRESS_ROOT}/health.txt

echo "Injecting Load Balancer HTTPS fix and domain definitions into $${WP_CONFIG_PATH}..."

# Using awk to insert the required PHP code and set the domain to the root domain.
awk '
  /require_once\(ABSPATH \. '\''wp-settings\.php'\''\);/ {
    print "//  START OF CLOUD LOAD BALANCER HTTPS FIX ";
    print "// WordPress must recognize the X-Forwarded-Proto header sent by the Google Cloud Load Balancer";
    print "if (isset(\$_SERVER[\x27HTTP_X_FORWARDED_PROTO\x27]) && \$_SERVER[\x27HTTP_X_FORWARDED_PROTO\x27] === \x27https\x27) {";
    print "    \$_SERVER[\x27HTTPS\x27] = \x27on\x27;";
    print "}";
    print "";
    print "// Ensure all site links use HTTPS and the correct domain (${wp_domain})";
    print "define(\x27WP_HOME\x27,\x27https://${wp_domain}\x27);";
    print "define(\x27WP_SITEURL\x27,\x27https://${wp_domain}\x27);";
    print "//  END OF CLOUD LOAD BALANCER HTTPS FIX ";
  }
  { print }
' "$$WP_CONFIG_PATH" > "$${WP_CONFIG_PATH}.tmp" && sudo mv "$${WP_CONFIG_PATH}.tmp" "$$WP_CONFIG_PATH"


# --- 9. Final Web Server Restart ---
# Restart httpd to load all new configurations (SSL, Firewall, SELinux policies)
echo "Final restart of httpd service..."
systemctl restart httpd
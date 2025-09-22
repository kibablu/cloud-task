**Nginx Reverse Proxy with SSL/TLS using Certbot**

This repository provides a comprehensive guide and configuration examples for setting up a secure Nginx reverse proxy. The guide details how to obtain and automatically renew a free SSL/TLS certificate from Let's Encrypt using Certbot and configure Nginx to securely serve your web application. The instructions are built around a common three-tier web architecture consisting of a dedicated proxy server, a web server, and a database server.

🏛️ **Architecture Overview**

The following diagram illustrates the high-level architecture. Nginx acts as a reverse proxy, handling all incoming public traffic and redirecting it securely to an internal application server.

<img src="images/dig-1.png" alt="architecture diagram" width="500"/>

📋 **Prerequisites**

Before you begin, ensure you have:

- A running Nginx server.
- A registered domain name with DNS records pointing to your Nginx server's public IP address.
- A running web application on an internal port.

⚙️ **Installation and Setup**

1. Install Certbot
First, you need to install Certbot and its Nginx plugin. These packages are available through the `epel` (Extra Packages for Enterprise Linux) repository on CentOS/RHEL-based systems.

```
sudo yum install epel-release
sudo yum install certbot python3-certbot-nginx
```

2. Obtain an SSL/TLS Certificate
Run Certbot to automatically obtain and install a certificate for your domain. This command will also modify your Nginx configuration to enable HTTPS.

**Important**: Replace example.com with your actual domain name.

```
sudo certbot --nginx -d example.com -d [www.example.com](https://www.example.com)
```
_edit with your actual domain name you registered_

Certbot will automatically configure Nginx to listen on port 443 (HTTPS) and serve your domain securely.

3. Configure Nginx as a Reverse Proxy
After Certbot has run, you need to edit your Nginx server block to function as a reverse proxy.

Locate your server configuration file, typically found in `/etc/nginx/conf.d/` or `/etc/nginx/sites-enabled/`. Edit the `server` block for your domain.

>Certbot modifies your NGINX configuration to listen on port 443 (HTTPS) and serve your domain securely. However, you'll need to manually adjust the configuration to act as a reverse proxy.
>The file is typically located in /etc/nginx/conf.d/ or /etc/nginx/sites-enabled/. Find the server block for your domain. It should look something like this after Certbot has run:

```
server {
    listen 443 ssl;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # The following block is what you need to add for the reverse proxy
    location / {
        proxy_pass http://localhost:8080; # Replace with the actual address and port of your application
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Optional: Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}
```
The nginx config file

```
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;


        location / {
            proxy_pass http://Internal IP webserver:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
    }
```

4. Test and Apply the Configuration
Validate your new Nginx configuration and reload the service to apply the changes.

```
sudo nginx -t
sudo systemctl reload nginx
```
⚠️ **Troubleshooting**

***SELinux Permission Errors***

If you encounter issues where your web application's content (e.g., product data from a database) is not rendering, it may be due to SELinux security policies preventing Nginx from accessing the network.

To resolve this, you can grant Nginx the necessary permissions by running the following command:
```
sudo setsebool -P httpd_can_network_connect 1
```
This command permanently enables the `httpd_can_network_connect` boolean, allowing processes managed by Nginx to make outgoing network connections. For more details on SELinux, consult the official documentation.

# 🛡️ Nginx Reverse Proxy with SSL/TLS via Certbot

This repository provides a comprehensive, production-ready guide and example configurations for deploying a secure Nginx reverse proxy with automatic SSL/TLS from Let’s Encrypt (Certbot).  
The setup is ideal for a common three-tier web architecture, with a dedicated proxy server, internal web application server, and a database server.

---

## 🏛️ Architecture Overview

Nginx acts as a reverse proxy, handling all incoming public traffic and forwarding it securely to your internal application server.

<img src="images/dig-1.png" alt="architecture diagram" width="500"/>

## 📋 Prerequisites

Before you begin, ensure you have:

- A running Nginx server (CentOS/RHEL, Ubuntu, or similar).
- A registered domain name with DNS A/AAAA records pointing to your Nginx server’s public IP.
- An internal web application server (e.g., http://localhost:8080 or another private IP:port).
- (Recommended) Root or sudo privileges on the server.

---

## ⚙️ Installation & Setup

### 1. Install Certbot and the Nginx Plugin

On CentOS/RHEL:
```sh
sudo yum install epel-release
sudo yum install certbot python3-certbot-nginx
```

On Ubuntu/Debian:
```sh
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

---

### 2. Obtain and Install a Let’s Encrypt SSL/TLS Certificate

Replace `example.com` with your actual domain name:
```sh
sudo certbot --nginx -d example.com -d www.example.com
```
Certbot will:
- Automatically configure Nginx for HTTPS (port 443).
- Fetch and install certificates.
- Set up automatic renewal.

---

### 3. Configure Nginx as a Reverse Proxy

After running Certbot, adjust your Nginx server block (typically in `/etc/nginx/conf.d/` or `/etc/nginx/sites-enabled/`):

```nginx
server {
    listen 443 ssl;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Reverse proxy configuration
    location / {
        proxy_pass http://localhost:8080; # Replace with your application's IP:port
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# (Optional) Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}
```

**Sample Nginx Config File**

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

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
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;

        location / {
            proxy_pass http://<INTERNAL_WEB_SERVER_IP>:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        include /etc/nginx/default.d/*.conf;
    }
}
```
> Replace `<INTERNAL_WEB_SERVER_IP>` with your internal app server’s address.

---

# Optional: Redirect HTTP to HTTPS
```
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}
```
### 4. Test and Reload Nginx

```sh
sudo nginx -t
sudo systemctl reload nginx
```

---

4. Test and Apply the Configuration
Validate your new Nginx configuration and reload the service to apply the changes.

```
sudo nginx -t
sudo systemctl reload nginx
```
---

## ⚠️ Troubleshooting

### SELinux Permission Errors

If your web application isn’t rendering content (e.g., cannot fetch data from a database), SELinux may be blocking Nginx from making network connections.

Grant Nginx the necessary permissions:
```sh
sudo setsebool -P httpd_can_network_connect 1
```
This command allows processes managed by Nginx (such as PHP-FPM or proxy connections) to make outgoing network connections.

---

## 🔒 Security Tips

- Certbot will auto-renew your certificates. To test renewal:
  ```sh
  sudo certbot renew --dry-run
  ```
- Never expose your internal app server directly to the internet.
- Regularly update Nginx and system packages.

---

## 📚 References & Further Reading

- [Nginx Documentation](http://nginx.org/en/docs/)
- [Let’s Encrypt / Certbot Docs](https://certbot.eff.org/)
- [SELinux Booleans for Nginx](https://wiki.centos.org/HowTos/SELinux)
- [Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

---

**Securely serve your apps with Nginx, Certbot, and best practices!**
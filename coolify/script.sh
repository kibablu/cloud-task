#!/bin/bash

# --- 1. Site Creation ---
# Create a new site entry in the Frappe Bench.
# This command initializes the site folder and creates the database in MariaDB.
bench new-site erpnext.klaudmazoezi.top \
  --admin-password "secure_password_123" \
  --mariadb-root-password "123"

# --- 2. App Installation ---
# Install the ERPNext application onto our newly created site.
# Note: By default, a site only contains the 'frappe' framework.
bench --site erpnext.klaudmazoezi.top install-app erpnext

# --- 3. Default Site Configuration ---
# Set this site as the 'current' or default site for the bench.
# This allows you to run bench commands without needing to type --site every time.
bench use erpnext.klaudmazoezi.top

# Verify that ERPNext was installed successfully on the site.
bench --site erpnext.klaudmazoezi.top list-apps

# --- 4. Database Permission Fix (MariaDB) ---
# Sometimes, site credentials fall out of sync or face connection issues.
# These SQL commands manually update the database user's password directly in MariaDB.
# [Note: You should run these inside the 'bench mariadb' console or a mysql prompt]
# ALTER USER '_5d7083dd41056f28'@'%' IDENTIFIED BY 'secure_password_123';
# FLUSH PRIVILEGES;
# EXIT;

# --- 5. Site Config Update ---
# Update the local site_config.json file to match the password we just set in MariaDB.
# This ensures the Python backend can authenticate with the database.
bench --site erpnext.klaudmazoezi.top set-config db_password secure_password_123
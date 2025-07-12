#Use the official PHP 7.4 image with an Apache web server.
FROM php:7.4-apache

# Install the mysqli extension for database connectivity.
# `docker-php-ext-install` is a helper script provided by the base image
# to easily install and enable PHP extensions.
RUN docker-php-ext-install mysqli

# Copy the application source code from the current directory to the Apache document root.
COPY . /var/www/html/

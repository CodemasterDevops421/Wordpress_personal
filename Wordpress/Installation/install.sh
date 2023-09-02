#!/bin/bash

# Prompt for MySQL and WordPress passwords
read -p "Enter MySQL password for user 'wordpress': " mysql_password

# Update the package list and install necessary packages
apt update
apt install -y nginx mysql-server php-fpm php-mysql unzip wget

# Start and enable Nginx, MySQL, and PHP-FPM
systemctl start nginx
systemctl enable nginx
systemctl start mysql
systemctl enable mysql
systemctl start php8.1-fpm
systemctl enable php8.1-fpm

# Set up MySQL database for WordPress
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '${mysql_password}';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Download and extract WordPress
wget https://wordpress.org/latest.zip
unzip latest.zip
cp -R wordpress/* /var/www/html/

# Change permissions
chown -R www-data:www-data /var/www/html/

# Create Nginx server block file for WordPress
echo 'server {
    listen 80;
    root /var/www/html;
    index index.php;
    server_name _;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}' > /etc/nginx/sites-available/wordpress

# Check if symbolic link already exists; if not, create it
if [ ! -e /etc/nginx/sites-enabled/wordpress ]; then
    ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
else
    echo "Symbolic link already exists. Skipping..."
fi

nginx -s reload

# Basic WordPress wp-config setup
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s|database_name_here|wordpress|g" /var/www/html/wp-config.php
sed -i "s|username_here|wordpress|g" /var/www/html/wp-config.php
sed -i "s|password_here|${mysql_password}|g" /var/www/html/wp-config.php

echo "WordPress has been installed. Please complete the setup in your web browser."

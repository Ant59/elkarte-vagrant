#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

shopt -s extglob

echo "Provisioning virtual machine..."
apt-get update > /dev/null

# Git
echo "Installing Git"
apt-get install git -y > /dev/null

# Nginx
echo "Installing Nginx"
apt-get install nginx -y > /dev/null

# PHP
echo "Updating PHP repository"
apt-get install python-software-properties -y > /dev/null
add-apt-repository ppa:ondrej/php5-5.6 -y > /dev/null
apt-get update > /dev/null

echo "Installing PHP"
apt-get install php5-common php5-dev php5-cli php5-fpm -y > /dev/null

echo "Installing PHP extensions"
apt-get install curl php5-curl php5-gd php5-mcrypt php5-mysql -y > /dev/null

echo "Configuring PHP"
cp -f /tmp/provision/php.ini /etc/php5/fpm/

# MySQL 
echo "Preparing MySQL"
apt-get install debconf-utils -y > /dev/null
debconf-set-selections <<< "mysql-server mysql-server/root_password password 1234"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 1234"

echo "Installing MySQL"
apt-get install mysql-server -y > /dev/null

# Setup Elkarte
echo "Setting up Elkarte"
cat /tmp/provision/database.sql | mysql -u root -p1234
cp -rf /tmp/elkarte/!(sources|install) /var/www/
cp -f /tmp/provision/Settings.php /var/www/

# Nginx Configuration
echo "Configuring Nginx"
cp -f /tmp/provision/nginx_vhost /etc/nginx/sites-available/nginx_vhost > /dev/null
ln -s /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/

rm -rf /etc/nginx/sites-available/default

# Restart Nginx for the config to take effect
service nginx restart > /dev/null

# Fix permissions
chown -R www-data:www-data /var/www/!(sources)
chmod -R 755 /var/www/!(sources)

echo "Finished provisioning"
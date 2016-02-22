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
add-apt-repository ppa:ondrej/php5-5.6 -y > /dev/null 2>&1
apt-get update > /dev/null

echo "Installing PHP"
apt-get install php5-common php5-dev php5-cli php5-fpm -y > /dev/null 2>&1

echo "Installing PHP extensions"
apt-get install curl php5-curl php5-gd php5-mcrypt php5-mysql php5-xdebug -y > /dev/null 2>&1

echo "Configuring PHP"
cp -f /vagrant/provision/php.ini /etc/php5/fpm/

# MySQL 
echo "Preparing MySQL"
apt-get install debconf-utils -y > /dev/null 2>&1
debconf-set-selections <<< "mysql-server mysql-server/root_password password 1234"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 1234"

echo "Installing MySQL"
apt-get install mysql-server -y > /dev/null 2>&1

# phpMyAdmin
echo "Preparing phpMyAdmin"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password 1234"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password 1234"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password 1234"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"

echo "Install phpMyAdmin"
apt-get install phpmyadmin -y > /dev/null 2>&1
ln -s /usr/share/phpmyadmin/ /var/www

# Elkarte
echo "Setting up Elkarte"
cp -f /vagrant/provision/Settings.php /var/www/
mysql -u root -p1234 -e 'CREATE DATABASE IF NOT EXISTS `elkarte` DEFAULT CHARACTER SET utf8'
php /vagrant/provision/install.php

# Nginx Configuration
echo "Configuring Nginx"
cp -f /vagrant/provision/nginx_vhost /etc/nginx/sites-available/nginx_vhost > /dev/null
ln -s /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/ > /dev/null 2>&1

rm -f /etc/nginx/sites-available/default

# Restart Nginx for the config to take effect
service nginx restart > /dev/null

# Install PHPUnit
echo "Installing PHPUnit"
wget https://phar.phpunit.de/phpunit.phar > /dev/null 2>&1
chmod +x phpunit.phar
mv phpunit.phar /usr/bin/phpunit

echo "Finished provisioning"
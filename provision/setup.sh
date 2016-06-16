#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

shopt -s extglob

echo "Provisioning virtual machine..."
apt-get update > /dev/null

# PPAs
echo "Adding repositories"
apt-get install software-properties-common -y > /dev/null
add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db > /dev/null 2>&1
add-apt-repository 'deb http://lon1.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu trusty main'
apt-get update > /dev/null

# debconf
echo "Setting selections"
apt-get install debconf-utils -y > /dev/null 2>&1

debconf-set-selections <<< "mariadb-server-10.1 mysql-server/root_password password 1234"
debconf-set-selections <<< "mariadb-server-10.1 mysql-server/root_password_again password 1234"

debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password 1234"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password 1234"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password 1234"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"

# Git
echo "Installing Git"
apt-get install git -y > /dev/null

# Nginx
echo "Installing Nginx"
apt-get install nginx -y > /dev/null

# PHP
echo "Installing PHP"
apt-get install php7.0-common php7.0-dev php7.0-cli php7.0-fpm -y > /dev/null 2>&1

echo "Installing PHP extensions"
apt-get install curl php7.0-curl php7.0-gd php7.0-mcrypt php7.0-mysql php7.0-xdebug -y > /dev/null 2>&1

# MariaDB
echo "Installing MariaDB"
apt-get install mariadb-server-10.1 -y > /dev/null 2>&1

# phpMyAdmin
echo "Installing phpMyAdmin"
apt-get install phpmyadmin -y > /dev/null 2>&1
ln -s /usr/share/phpmyadmin/ /var/www > /dev/null 2>&1

# Elkarte
echo "Setting up Elkarte"
cp -f /vagrant/provision/Settings.php /var/www/
mysql -u root -p1234 -e "CREATE DATABASE IF NOT EXISTS elkarte DEFAULT CHARACTER SET utf8"
mysql -u root -p1234 -e "GRANT ALL PRIVILEGES ON elkarte.* TO 'elkarte'@'localhost' IDENTIFIED BY '1234'"
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

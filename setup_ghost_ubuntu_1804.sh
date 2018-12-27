#!/bin/bash

# This file is designed to take a vanilla instance of Ubuntu 18.04 
# and install and setup Ghost CMS and its dependencies.

ROOT_DB_PASSWORD=`openssl rand -base64 32`
GHOSTCMS_USER_PASSWORD=`openssl rand -base64 32`
GHOST_DB_NAME=ghost_prod
GHOST_DB_USER=ghostuser
GHOST_DB_PASSWORD=`openssl rand -base64 32`


apt-get update
apt-get upgrade -y

apt-get install -y nginx
ufw allow 'Nginx Full'

## DB Setup
apt-get install -y mariadb-server mariadb-client

## Setup DB for Ghost
mysql -e "CREATE DATABASE ${GHOST_DB_NAME}"
mysql -e "CREATE USER '${GHOST_DB_USER}'@'localhost' IDENTIFIED BY '${GHOST_DB_PASSWORD}'"
mysql -e "GRANT ALL ON ${GHOST_DB_NAME}.* TO '${GHOST_DB_USER}'@'localhost'"
mysql -e "FLUSH PRIVILEGES"

## Lock down DB server
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${ROOT_DB_PASSWORD}') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd para

## END: DB Setup

#TODO not sure about exec from internet!!!
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash
apt-get install -y nodejs

npm install ghost-cli@latest -g

adduser --disabled-password --disabled-login --gecos "Ghost CMS setup user" ghostcms
echo ghostcms:$GHOSTCMS_USER_PASSWORD | chpasswd
usermod -aG sudo ghostcms

mkdir -p /var/www/ghost
chown ghostcms:ghostcms /var/www/ghost
chmod 775 /var/www/ghost

echo "Please record these details somewhere safe:"
echo "MySQL root user password: $ROOT_DB_PASSWORD"
echo "MySQL DB name: $GHOST_DB_NAME"
echo "MySQL Ghost username: $GHOST_DB_USER"
echo "MySQL $GHOST_DB_USER password: $GHOST_DB_PASSWORD"
echo "System user ghostcms password: $GHOSTCMS_USER_PASSWORD" 
su - ghostcms -c "cd /var/www/ghost && ghost install"

# Am repeating here in case they got lost in other stdout
echo "Please record these details somewhere safe:"
echo "MySQL root user password: $ROOT_DB_PASSWORD"
echo "MySQL DB name: $GHOST_DB_NAME"
echo "MySQL Ghost username: $GHOST_DB_USER"
echo "MySQL $GHOST_DB_USER password: $GHOST_DB_PASSWORD"
echo "System user ghostcms password: $GHOSTCMS_USER_PASSWORD" 

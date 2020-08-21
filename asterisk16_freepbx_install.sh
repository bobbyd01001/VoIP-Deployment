#!/bin/bash

# Copyright 2020 Beawit Consulting LLC
# Author: JC Beasley 
# Email: beaswork@gmail.com

#feel free to tweek and adjust to fit your need

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Usage: # installer for asterisk 16 with freepbx 15 running on Debian Buster 10

####VARIABLES GO HERE####

#####FUNCTIONS GO HERE####
# ensure running as root
# initiate super user access, enter password when prompted
function SUPERYOU(){
if [ "$(id -u)" != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    exec sudo "$0" "$@"
    exit 1
elif [ "$(id -u)" = "0" ]; then
    echo "Hello superuser"
fi
}

# ensure running as root
SUPERYOU
# STEP 1 
# INSTALL ASTERISK 1ST
echo "ASTERISK FREEPBX INSTALLATION ON DEBIAN BUSTER 10"
echo "get ready!!!"
# update the system 
echo "5"
sleep 2
echo "4"
sleep 2
echo "3"
sleep 2
echo "2"
sleep 2
echo "1"
sleep 2
echo "Lets Begin"
sleep 3
apt update && apt -y upgrade

# install asterisk 16 LTS dependencies
echo "NOW I WILL INSTALL ASTERISK DEPENDENCIES......"
sleep 3
apt -y install git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev  uuid-dev

# download asterisk 16 LTS tarball
clear
echo "NOW LETS DOWNLOAD ASTERISK....."
cd /usr/src
curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
echo ""
echo "DOWNLOAD COMPLETE!!"
sleep 3

# extract the file
echo "EXTRACTING ASTERISK......."
sleep 3
tar xvf asterisk-16-current.tar.gz
cd asterisk-16*/
echo ""
echo "EXTRACTION COMPLETE....."

# download mp3 decoder library
echo "NOW I WILL DOWNLOAD MP3 DECODER LIBRARY....."
sleep 3
contrib/scripts/get_mp3_source.sh

# ensure all dependencies are resolved
clear
echo "I WILL NOW ENSURE ALL DEPENDENCIES ARE RESOLVED....."
contrib/scripts/install_prereq install
echo ""
echo "COMPLETE....."
sleep 3
# Run the configure script to satisfy build dependencies
./configure

# Setup menu options by running the following command:
make menuselect

# use keyboard to navigate and select addons

#build asterisk
echo "Creating Asterisk Build........"
sleep 3
make
clear

# install asterisk
echo "Installing Asterisk........"
sleep 3
make install
clear

# optionally install documentation
echo "I will install standard documentation....."
sleep 3
make progdocs

# Finally, install configs and samples
make samples
make config
ldconfig

# Create Asterisk user
clear
echo "Creating the Asterisk User....."
sleep 3
groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk.asterisk /usr/lib/asterisk

# Set Asterisk default user to asterisk:
#nano /etc/default/asterisk
# add the following lines
echo 'AST_USER=asterisk' >> /etc/default/asterisk
echo 'AST_GROUP=asterisk' >> /etc/default/asterisk


#nano /etc/asterisk/asterisk.conf
# add the following lines
echo 'runuser = asterisk ; The user to run as.' >> /etc/asterisk/asterisk.conf
echo 'rungroup = asterisk ; The group to run as.' >> /etc/asterisk/asterisk.conf

# Restart asterisk service after making the changes:
systemctl restart asterisk

# Enable asterisk service to start on system  boot:
systemctl enable asterisk
/lib/systemd/systemd-sysv-install enable asterisk
# Service should be running without errors:
systemctl status asterisk

# ASTERISK INSTALL COMPLETE
echo "ASTERISK INSTALL COMPLETE"
sleep 3 
clear
echo ""
echo "INSTALLING MARIADB DATABASE SERVER"
sleep 3
# STEP 2 Install MariaDB Database server:
apt update
apt -y install mariadb-server mariadb-client


clear
echo "Installing NODEJS from repository......."
sleep 3
# STEP 3 INSTALL NODEJS
# configure Node.js APT repository to your OS
apt -y install dirmngr apt-transport-https lsb-release ca-certificates
curl -sL https://deb.nodesource.com/setup_12.x | bash -

# Install Node.js 10|12 LTS on Ubuntu & Debian
apt update
apt -y install gcc g++ make
apt -y install nodejs

 # install the Yarn package manager
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update && apt-get install yarn
clear
# Confirm Node version
echo "Installed NODEJS version"
node -v
sleep 3

clear
echo "I will now install Apache web Server......"
sleep 3
# Install apache2 package from apt:
apt -y install apache2

# change Apache user to asterisk and turn on AllowOverride option
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

echo "I will remove the default html index file....."
# remove default index.html page
rm -f /var/www/html/index.html
echo "DONE!!!"
sleep 3
clear
#  Install PHP and required extensions
echo "Now Installing PHP and required extensions"
sleep 3
apt -y install php php-pear php-cgi php-common php-curl php-mbstring php-gd php-mysql php-gettext php-bcmath php-zip php-xml php-imap php-json php-snmp php-fpm libapache2-mod-php sox

# Change php maximum file upload size
# For Debian 10
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/7.*/apache2/php.ini
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/7.*/cli/php.ini
sed -i 's/\(^memory_limit = \).*/\256M/' /etc/php/7.*/apache2/php.ini

clear
echo "Now I will download and install FreePBX version 15....."
sleep 3
# Download the latest version of FreePBX 15:
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-15.0-latest.tgz

# Extract the file:
tar xfz freepbx-15.0-latest.tgz
rm -f freepbx-15.0-latest.tgz

# Install FreePBX 15 on Ubuntu 20.04/18.04 / 16.04 & Debian 10/9
cd freepbx
./start_asterisk start
./install -n


# Enable Apache Rewrite engine and restart apache2
a2enmod rewrite
systemctl restart apache2

echo "open your web browser to http://host_ip/"

echo "to complete post installation...."























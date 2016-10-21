#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]
then
    echo "ERROR: You must be root to run this script, use sudo sh $0";
        exit 1;    
fi

echo "Adding repository for the Jenkins package"
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -

echo "Adding the package repository to the list of repositories"
echo "deb http://pkg.jenkins-ci.org/debian binary/" | sudo tee -a /etc/apt/sources.list.d/jenkins.list

echo "Updating package"
sudo apt-get update

echo "Installing Jenkins"
sudo apt-get -y install jenkins

echo "Starting Jenkins"
sudo service jenkins start

echo "Installing Apache server"
sudo apt-get -y install apache2
sudo a2enmod proxy
sudo a2enmod proxy_http

echo "<VirtualHost *:80>
    ServerName jenkins.fabfitfun.com
    ProxyRequests Off
    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>
    ProxyPreserveHost on
    ProxyPass / http://localhost:8080/
</VirtualHost>" | sudo tee /etc/apache2/sites-available/jenkins.conf

sudo a2ensite jenkins
sudo service apache2 reload
sudo service apache2 restart

sudo apt-get -y install git
sudo apt-get -y install phpunit

#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]
then
    echo "ERROR: You must be root to run this script, use sudo sh $0";
        exit 1;    
fi

# Uninstall just jenkins
apt-get remove jenkins

#Uninstall jenkins and its dependencies
apt-get remove --auto-remove jenkins

#Purging your config/data too
sudo apt-get purge jenkins
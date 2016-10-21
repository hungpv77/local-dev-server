#!/bin/bash
apache_config_file="/etc/apache2/envvars"
apache_vhost_file="/etc/apache2/sites-available/000-default.conf"
apache_vhost_ssl_file="/etc/apache2/sites-available/default-ssl.conf"
php_config_file="/etc/php5/apache2/php.ini"
xdebug_config_file="/etc/php5/mods-available/xdebug.ini"

# MySQL config file
mysql_config_file="/etc/mysql/my.cnf"



main() {
	# Check if user is root
    if [ $(id -u) != "0" ]
    then
        echo "ERROR: You must be root to run this script, use sudo sh $0";
        exit 1;    
    fi
    update_package_list
    install_util_tools
    install_apache
    install_php
    install_mysql 
	install_jenkins
    #autoremove     
}

update_package_list() {
    # Update the server
    echo "INFO: Updating package list..."
    apt-get update
}

autoremove() {
    apt-get -y autoremove
}


install_util_tools() {
    # Install basic tools
    echo "INFO: Installing basic tools..."
    apt-get -y install build-essential binutils-doc git subversion unzip
}

install_apache() {
    # Install Apache
    echo "INFO: Installing apache2..."
    apt-get -y install apache2

    #sed -i "s/^\(.*\)www-data/\1$USER/g" ${apache_config_file}
    #chown -R $USER:$USER /var/log/apache2        

    # Enable rewrite mod and ssl mode
    a2enmod rewrite
    a2enmod ssl
}

install_php() {
    # Install php
    echo "INFO: Installing php5..."
    apt-get -y install php5 php5-curl php5-mysql php5-sqlite php5-xdebug php-pear php5-dev phpunit

    sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_config_file}
    sed -i "s/display_errors = Off/display_errors = On/g" ${php_config_file}

    if [ ! -f "{$xdebug_config_file}" ]; then
        cat << EOF > ${xdebug_config_file}
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_host=10.0.2.2
EOF
    fi

    service apache2 reload

    # Install latest version of Composer globally
    if [ ! -f "/usr/local/bin/composer" ]; then
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    fi

    # Install PHP Unit 4.8 globally
    if [ ! -f "/usr/local/bin/phpunit" ]; then
        curl -O -L https://phar.phpunit.de/phpunit-old.phar
        chmod +x phpunit-old.phar
        mv phpunit-old.phar /usr/local/bin/phpunit
    fi
}

install_mysql() {
    # Install MySQL
    echo "-------------------------------------"
    echo "INFO: Updating package"
    apt-get update
    
    # Does not ask us questions for a root password and all that.
    echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

    echo "INFO: Installing MySQL Server"
    apt-get -y install mysql-client-5.6 mysql-server-5.6

    echo "INFO: Modifying configuration file..."
    sed -i "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" ${mysql_config_file}
    sed -i "s/key_buffer/key_buffer_size/" ${mysql_config_file}
    sed -i "s/myisam-recover/myisam-recover-options/" ${mysql_config_file}

    echo "INFO: Allow root access from any host"
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION" | mysql -u root --password=root
    echo "GRANT PROXY ON ''@'' TO 'root'@'%' WITH GRANT OPTION" | mysql -u root --password=root
    echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('vVDMGFJFQtaDxHWLhA96BFW4')" | mysql -u root --password=root
    
    service mysql restart    
}

install_jenkins(){
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
}


main
exit 0



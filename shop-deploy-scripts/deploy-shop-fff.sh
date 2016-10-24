#!/bin/bash
jenkins_workspace="/var/lib/jenkins/workspace/shop-fabfitfun/"
apache_vhost_dir="/etc/apache2/sites-available/"
#branchname.reponame.fffdev.com

# Get the path of directory that contains executing script
script_dir=${PWD}

# Read server info
source ../servers-info

reponame="shop"
repository_url="git@github.com:hungpv77/shop-fabfitfun.git"

main(){
    # Check if user is root
    if [ $(id -u) != "0" ]
    then
        echo "ERROR: You must be root to run this script, use sudo sh $0";
        exit 1;    
    fi

    git_branch=$( get_branch_name )
    
    # replace / by _
    dir_branch=$(echo $git_branch | sed 's@/@_@g')
    # replace - by _
    dir_branch=$(echo $dir_branch | sed 's@-@_@g')

    shop_db_name="${dir_branch}_${shop_db}"
    core_db_name="${dir_branch}_${core_db}"

    server_dir="${www_dir}${dir_branch}.${reponame}"

    domain_name="${dir_branch}.${reponame}.${domain}"

    echo "INFO: Adding SSH key to the ssh-agent"
    eval "$(sudo ssh-agent -s)"
    ssh-add $rsa_file

    # If this branch is existing, just pull code
    if [ -d "$server_dir" ]; then
        echo "INFO: Pulling Code..."
        cd $server_dir
        git pull origin $git_branch
        update_data ${server_dir} ${shop_db_name}
    else
        echo "INFO: Starting install shop..."
        install_shop ${dir_branch} ${git_branch} ${shop_db_name} ${core_db_name}
        add_virtual_hosts ${dir_branch}
        add_ssl_virtual_hosts ${dir_branch}
        create_databases ${shop_db_name} ${core_db_name}
        config_url_data ${shop_db_name} ${domain_name}
        update_data ${server_dir} ${shop_db_name}
        call_route53_api ${domain_name}
    fi        
}


install_shop(){
    echo "DEBUG: install_shop()..."
    server_dir="${www_dir}$1.${reponame}"
    server_name="$1.${reponame}.${domain}"
    mkdir -p $server_dir      

    # Clone code from repository        
    echo "git clone -b $2 ${repository_url}"
    
    git clone -b $2 ${repository_url} "$server_dir/"

    echo "INFO: Creating wp-config for shop"     
    wp_config_file="$server_dir/wp-config.php"
    # Since the code base doen't have wp-config.php any more, we need to copy it from predefined config folder.
    if [ -f "$script_dir/config/shop-config.php" ]; then
        cp "$script_dir/config/shop-config.php" $wp_config_file
    else
        echo "ERROR: shop-config.php is not exist."  
    fi 

    echo "INFO: Creating .htaccess for shop"
    if [ -f "$script_dir/config/shop-htaccess" ]; then
        cp "$script_dir/config/shop-htaccess" "$server_dir/.htaccess"        
    else
        echo "ERROR: shop-htaccess is not exist."  
    fi

    echo "INFO: replace db name variable in htaccess" 
    sed -i "s@SetEnv ENV_SHOP_DB_NAME.*@SetEnv ENV_SHOP_DB_NAME $3@" "$server_dir/.htaccess"
    sed -i "s@SetEnv ENV_CORE_DB_NAME.*@SetEnv ENV_CORE_DB_NAME $4@" "$server_dir/.htaccess"

    echo "INFO: replace server name variable in htaccess" 
    sed -i "s@---ServerName---@$server_name@" "$server_dir/.htaccess"
    
    cd "$server_dir/hashidsphp/"
    sudo composer install    
}

add_virtual_hosts() {
    echo "DEBUG: add_virtual_hosts()..."
    server_dir="${www_dir}$1.${reponame}"
    server_name="$1.${reponame}.${domain}"
	
    echo "INFO: $server_dir"
    apache_vhost_file="${apache_vhost_dir}$1.${reponame}.conf"
    echo "INFO: Copying file 000-default.conf to $apache_vhost_file"    
    if [ -f "$script_dir/config/shop-vhost-template.conf" ]; then
        cp "$script_dir/config/shop-vhost-template.conf" $apache_vhost_file
    else
        echo "ERROR: 000-default.conf is not exist."        
    fi
    echo "INFO: replace server name variable in $apache_vhost_file" 
    sed -i "s@---ServerName---@$server_name@" ${apache_vhost_file}
    sed -i "s@---ServerDir---@$server_dir@" ${apache_vhost_file}
    
    a2ensite "$1.${reponame}.conf"
    service apache2 reload
    service apache2 restart
}

add_ssl_virtual_hosts() {
    echo "DEBUG: add_ssl_virtual_hosts()..."

    server_dir="${www_dir}${1}.${reponame}"

    # Copy ssl cert and key
    if [ ! -d  "/etc/apache2/ssl" ]; then
        mkdir "/etc/apache2/ssl"
    fi
    cp "$server_dir/localshop.fabfitfun.dev.crt" "/etc/apache2/ssl/"
    cp "$server_dir/localshop.fabfitfun.dev.key" "/etc/apache2/ssl/"
    
    apache_vhost_ssl_file="${apache_vhost_dir}$1.${reponame}-ssl.conf"
    echo "INFO: Copying file default-ssl.conf to $apache_vhost_ssl_file"
    if [ -f "$script_dir/config/default-ssl-template.conf" ]; then
        cp "$script_dir/config/default-ssl-template.conf" $apache_vhost_ssl_file
    else
        echo "ERROR: default-ssl-template.conf is not exist."        
    fi

    echo "INFO: replace server name variable in $apache_vhost_ssl_file" 
    sed -i "s@---ServerName---@$server_name@" $apache_vhost_ssl_file
    echo "INFO: replace server dir variable in $apache_vhost_ssl_file"
    sed -i "s@---ServerDir---@$server_dir@" $apache_vhost_ssl_file    

    a2ensite "${branch_name}.${reponame}-ssl.conf"
    service apache2 reload
    service apache2 restart
}

call_route53_api(){    
    json_request='{
          "Comment": "Create a batch of A record sets",
          "Changes": [
            {
              "Action": "CREATE",
              "ResourceRecordSet": {
                "Name": '\"$1\"',
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                  {
                    "Value": '\"$dev_server_ip\"'
                  }
                ]
              }
            }
          ]
        }'
    aws route53 change-resource-record-sets  --hosted-zone-id $hosted_zone_id --change-batch "$json_request"
}

create_databases() {

    # Create Shop and Core databases
    echo "-------------------------------------"
    echo "INFO: Creating $1 database..."
    echo "DROP DATABASE IF EXISTS $1" | mysql -u root --password=${db_passwd}
    echo "CREATE DATABASE IF NOT EXISTS $1" | mysql -u root --password=${db_passwd}
    echo "INFO: Creating $2 database..."
    echo "DROP DATABASE IF EXISTS $2" | mysql -u root --password=${db_passwd}
    echo "CREATE DATABASE IF NOT EXISTS $2" | mysql -u root --password=${db_passwd}

    # Import data for databases
    import_data ${1} ${shop_db}
    import_data ${2} ${core_db}
}


import_data() {
     if [ -d "$db_path/$2" ]; then
        echo "-------------------------------------"
        echo "INFO: Importing schema for $1..."        
        for sql_file in $db_path/${2}/*schema*.sql
        do            
            time mysql -u root --password=${db_passwd} -f $1 < $sql_file            
            echo ""
        done

        echo "-------------------------------------"
        echo "INFO: Importing data for $1..."                
        for sql_file in $db_path/${2}/*data*.sql
        do
            echo "EXECUTING $sql_file..."        
            time mysql -u root --password=${db_passwd} -f $1 < $sql_file
            echo "FINISHED $sql_file"
            echo ""
        done

        
    else
        echo "ERROR: There is something wrong to import data."       
    fi
}

config_url_data() {
    echo "INFO: Updating database for $1"
        
    echo "UPDATE $1.shop_options SET option_value='$2' WHERE option_name='rootcookie_subdomain_manual'" | mysql -u root --password=${db_passwd}

    # Update shop_options table for siteurl and home
    echo "UPDATE $1.shop_options SET option_value='https://$2' WHERE option_name='siteurl'" | mysql -u root --password=${db_passwd}
    echo "UPDATE $1.shop_options SET option_value='https://$2' WHERE option_name='home'" | mysql -u root --password=${db_passwd}

    # Update wp_options table for siteurl and home
    echo "UPDATE $1.wp_options SET option_value='https://$2/magazine' WHERE option_name='siteurl'" | mysql -u root --password=${db_passwd}
    echo "UPDATE $1.wp_options SET option_value='https://$2/magazine' WHERE option_name='home'" | mysql -u root --password=${db_passwd}         
}

update_data(){
    echo "Update DB from $1/db_update.sql"
    mysql -u root --password=${db_passwd} -f $2 < $1/db_update.sql    
}

get_branch_name(){
    cd $jenkins_workspace
    # Get the SHA of the checked out commit
    sha=$(git rev-parse HEAD)

    # To get the all branches that commit, get the second line
    branch_name=$(git branch -a --contains ${sha} | sed -n 2p)

    #remove "remotes/origin/" out of branch name
    branch_name=$(echo $branch_name | sed 's@remotes/origin/@@')
        
    echo "$branch_name"
}

main
exit 0
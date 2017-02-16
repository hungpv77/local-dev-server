#!/bin/bash
jenkins_workspace="/var/lib/jenkins/workspace/core-blog/"
apache_vhost_dir="/etc/apache2/sites-available/"
#branchname.reponame.fffdev.com

# Get the path of directory that contains executing script
script_dir=${PWD}

# Read server info
source ../servers-info

reponame="magazine"
repository_url="git@github.com:fabfitfun/core-blog.git"

shop_vhost_file="/etc/apache2/sites-available/dev.shop.conf"
shop_ssl_vhost_file="/etc/apache2/sites-available/dev.shop-ssl.conf"


main(){
    # Check if user is root
    if [ $(id -u) != "0" ]
    then
        echo "ERROR: You must be root to run this script, use sudo sh $0";
        exit 1;    
    fi
	
	if [ "$opt" == "-b" ] || [ "$opt" == "--branch" ]; then
        git_branch=$branch_param
    else
        git_branch=$( get_branch_name )
    fi

	# Convert upper case to lower case	
    git_branch_lower=$(echo "$git_branch" | tr '[:upper:]' '[:lower:]')
    echo "INFO: trigger branch: $git_branch"
    
    # replace / by _
    dir_branch=$(echo $git_branch_lower | sed 's@/@_@g')
    # replace - by _
    dir_branch=$(echo $dir_branch | sed 's@-@_@g')

    blog_db_name="${dir_branch}_${reponame}_${shop_db}"

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
    else
        echo "INFO: Starting install blog..."
        install_blog ${dir_branch} ${git_branch} ${blog_db_name}
        add_virtual_hosts ${dir_branch}
        add_ssl_virtual_hosts ${dir_branch}
        create_databases ${blog_db_name}
        config_url_data ${blog_db_name} ${domain_name}        
        call_route53_api ${domain_name}      
    fi        
}


install_blog(){
    echo "DEBUG: install_blog()..."
    server_dir="${www_dir}$1.${reponame}"
    server_name="$1.${reponame}.${domain}"
    mkdir -p $server_dir    

    # Clone code from repository        
    echo "git clone -b $2 ${repository_url}"    
    git clone -b $2 ${repository_url} "$server_dir/"

    # Copy wp-config from predefined to Blog app
    echo "INFO: Creating config.local.php for Blog app"         
    config_local_file="$server_dir/web/config.local.php"
    if [ -f "$script_dir/config/config.local.php" ]; then
        cp "$script_dir/config/config.local.php" $config_local_file
    else
        echo "ERROR: blog-config.php is not exist."        
    fi

    sed -i "s@dev_ssoblog@$3@" ${config_local_file}

	echo "INFO: Creating wp-config.php for Blog app"         
    wp_config_file="$server_dir/web/wp-config.php"
    if [ -f "$script_dir/config/wp-config.php" ]; then
        cp "$script_dir/config/wp-config.php" $wp_config_file
    else
        echo "ERROR: wp-config.php is not exist."        
    fi	


    echo "INFO: Creating .htaccess file for Blog app"
    if [ -f "$script_dir/config/blog-htaccess" ]; then
        cp "$script_dir/config/blog-htaccess" "$server_dir/web/.htaccess"
    else
        echo "ERROR: api-htaccess is not exist."  
    fi

    header_file="$server_dir/web/wp-content/themes/braxton/header.php"
    echo "INFO: update /blog/web/wp-content/themes/braxton/header.php file"
    sed -i "s/www.fabfitfun.com/$server_name/" ${header_file} 
    sed -i "s@/magazine/category/life@/category/life@" ${header_file}
    sed -i "s@/magazine/category/get-well@/category/get-well@" ${header_file}
    sed -i "s@/magazine/category/entertainment@/category/entertainment@" ${header_file}
    sed -i "s@/magazine/category/get-gorgeous@/category/get-gorgeous@" ${header_file}
    sed -i "s@/magazine/category/get-stylish@/category/get-stylish@" ${header_file}     
 
}

add_virtual_hosts() {
    echo "DEBUG: add_virtual_hosts()..."
    server_dir="${www_dir}$1.${reponame}"
    server_name="$1.${reponame}.${domain}"
    
    echo "INFO: $server_dir"
    apache_vhost_file="${apache_vhost_dir}$1.${reponame}.conf"
    echo "INFO: Copying file blog-vhost-template.conf to $apache_vhost_file"    
    if [ -f "$script_dir/config/blog-vhost-template.conf" ]; then
        cp "$script_dir/config/blog-vhost-template.conf" $apache_vhost_file
    else
        echo "ERROR: blog-vhost-template.conf is not exist."        
    fi
    echo "INFO: replace server name variable in $apache_vhost_file" 
    sed -i "s@---ServerName---@$server_name@" ${apache_vhost_file}
    sed -i "s@---ServerDir---@$server_dir/web@" ${apache_vhost_file}
    
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
    sed -i "s@---ServerDir---@$server_dir/web@" $apache_vhost_ssl_file    

    a2ensite "$1.${reponame}-ssl.conf"
    service apache2 reload
    service apache2 restart
}

create_databases() {

    # Create Shop and Core databases
    echo "-------------------------------------"
    echo "INFO: Creating $1 database..."
    echo "DROP DATABASE IF EXISTS $1" | mysql -u root --password=${db_passwd}
    echo "CREATE DATABASE IF NOT EXISTS $1" | mysql -u root --password=${db_passwd}

    # Import data for databases
    import_data ${1} ${shop_db}    
}


import_data() {
     if [ -d "$db_path/$2" ]; then
        #echo "-------------------------------------"
        #echo "INFO: Importing schema for $1..."        
        #for sql_file in $db_path/${2}/*schema*.sql
        #do            
        #    time mysql -u root --password=${db_passwd} -f $1 < $sql_file            
        #    echo ""
        #done

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
    echo "UPDATE $1.shop_postmeta SET meta_value='https://$2' WHERE post_id=116 AND meta_key='_menu_item_url'" | mysql -u root --password=${db_passwd}

    echo "UPDATE $1.wp_options SET option_value='https://$2' WHERE option_name='siteurl'" | mysql -u root --password=${db_passwd}
    echo "UPDATE $1.wp_options SET option_value='https://$2' WHERE option_name='home'" | mysql -u root --password=${db_passwd} 

    # Update menu items
    echo "UPDATE $1.shop_postmeta pm INNER JOIN $1.shop_posts p ON pm.post_id=p.id
        SET pm.meta_value=REPLACE(pm.meta_value, 'http://www.fabfitfun.com', '')
        WHERE p.post_type='nav_menu_item' AND pm.meta_key='_menu_item_url' AND (INSTR(pm.meta_value, 'http://www.fabfitfun.com') > 0)" | mysql -u root --password=${db_passwd}

    echo "UPDATE $1.shop_postmeta pm INNER JOIN $1.shop_posts p ON pm.post_id=p.id
        SET pm.meta_value=REPLACE(pm.meta_value, 'https://www.fabfitfun.com', '')
        WHERE p.post_type='nav_menu_item' AND pm.meta_key='_menu_item_url' AND (INSTR(pm.meta_value, 'https://www.fabfitfun.com') > 0)" | mysql -u root --password=${db_passwd}

    echo "UPDATE $1.shop_postmeta pm INNER JOIN $1.shop_posts p ON pm.post_id=p.id
        SET pm.meta_value=REPLACE(pm.meta_value, 'http://fabfitfun.com', '')
        WHERE p.post_type='nav_menu_item' AND pm.meta_key='_menu_item_url' AND (INSTR(pm.meta_value, 'http://fabfitfun.com') > 0)" | mysql -u root --password=${db_passwd}

    echo "UPDATE $1.shop_postmeta pm INNER JOIN $1.shop_posts p ON pm.post_id=p.id
        SET pm.meta_value=REPLACE(pm.meta_value, 'https://fabfitfun.com', '')
        WHERE p.post_type='nav_menu_item' AND pm.meta_key='_menu_item_url' AND (INSTR(pm.meta_value, 'https://fabfitfun.com') > 0)" | mysql -u root --password=${db_passwd}        
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

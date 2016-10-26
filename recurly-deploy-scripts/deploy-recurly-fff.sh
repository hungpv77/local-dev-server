#!/bin/bash
jenkins_workspace="/var/lib/jenkins/workspace/recurly-push-notification/"
apache_vhost_dir="/etc/apache2/sites-available/"
#branchname.reponame.fffdev.com

# Get the path of directory that contains executing script
script_dir=${PWD}

# Read server info
source ../servers-info

reponame="recurly"
repository_url="git@github.com:fabfitfun/recurly-push-notification.git"


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

    server_dir="${www_dir}${dir_branch}.${reponame}"

    echo "INFO: Adding SSH key to the ssh-agent"
    eval "$(sudo ssh-agent -s)"
    ssh-add $rsa_file

    # If this branch is existing, just pull code
    if [ -d "$server_dir" ]; then
        echo "INFO: Pulling Code..."
        cd $server_dir
        git pull origin $git_branch
    else
        echo "INFO: Starting install shop..."
        install_recurly ${dir_branch} ${git_branch} 
        add_virtual_hosts ${dir_branch}
        call_route53_api ${dir_branch}
    fi        
}


install_recurly(){
    echo "DEBUG: install_api()..."
    server_dir="${www_dir}$1.${reponame}"
    server_name="$1.${reponame}.${domain}"
    mkdir -p $server_dir

    # Install CodeIgnitor framework first
    if [ ! -f "2.5.8.zip" ]; then
        #statements
        wget https://github.com/cakephp/cakephp/archive/2.5.8.zip            
    fi    
    unzip 2.5.8.zip
    rm 2.5.8.zip
 
    mv ./cakephp-2.5.8/* ${server_dir}
    rm -r cakephp-2.5.8/
        
    # Remove default app by the framework   
    if [ -d "$server_dir/app" ]; then        
        echo "INFO: Removing default app..."        
        rm -rf "$server_dir/app"
        mkdir "$server_dir/app"
    fi

    echo "-------------------------------------"
    echo "INFO: Cloning code from api git into $server_dir/app..."    
    

    # Clone code from repository        
    echo "git clone -b $2 ${repository_url}"
    cd "$server_dir/app"       
    git clone -b $2 ${repository_url} "."       
    
    chmod 777 -R ${www_dir}$1       
        
    echo "INFO: Creating database.php for Recurly app"          
    recurly_database_config="$server_dir/app/Config/database.php"    
    if [ -f "$script_dir/config/recurly-config.php" ]; then
        cp "$script_dir/config/recurly-config.php" $recurly_database_config
    else
        echo "ERROR: recurly-config.php is not exist."    
    fi

    echo "INFO: Creating .htaccess file for Recurly app"
    if [ -f "$script_dir/config/recurly-htaccess" ]; then
        cp "$script_dir/config/recurly-htaccess" "$server_dir/app/.htaccess"
    else
        echo "ERROR: recurly-htaccess is not exist."  
    fi

    cd "$server_dir"
    sudo composer install
    
    cd "$server_dir/app/Vendor/"
    sudo composer install

    cd "$server_dir/app/Vendor/analytics-php/"
    sudo composer install  

    cd "$server_dir/app/Vendor/WC/automattic/woocommerce/"
    sudo composer install      

}

add_virtual_hosts() {
    echo "DEBUG: add_virtual_hosts()..."
    server_dir="${www_dir}$1.${reponame}"
    server_name="$1.${reponame}.${domain}"
	
    echo "INFO: $server_dir"
    apache_vhost_file="${apache_vhost_dir}$1.${reponame}.conf"
    echo "INFO: Copying file recurly-vhost-template.conf to $apache_vhost_file"    
    if [ -f "$script_dir/config/recurly-vhost-template.conf" ]; then
        cp "$script_dir/config/recurly-vhost-template.conf" $apache_vhost_file
    else
        echo "ERROR: recurly-vhost-template is not exist."        
    fi
    echo "INFO: replace server name variable in $apache_vhost_file" 
    sed -i "s@---ServerName---@$server_name@" ${apache_vhost_file}
    sed -i "s@---ServerDir---@$server_dir@" ${apache_vhost_file}
    
    a2ensite "$1.${reponame}.conf"
    service apache2 reload
    service apache2 restart
}

call_route53_api(){
    server_name="$1.${reponame}.${domain}"
    json_request='{
          "Comment": "Create a batch of A record sets",
          "Changes": [
            {
              "Action": "CREATE",
              "ResourceRecordSet": {
                "Name": '\"$server_name\"',
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

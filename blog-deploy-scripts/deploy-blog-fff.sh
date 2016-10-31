#!/bin/bash
jenkins_workspace="/var/lib/jenkins/workspace/core-blog/"
apache_vhost_dir="/etc/apache2/sites-available/"
#branchname.reponame.fffdev.com

# Get the path of directory that contains executing script
script_dir=${PWD}

# Read server info
source ../servers-info

reponame="blog"
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

    git_branch=$( get_branch_name )
    echo "INFO: trigger branch: $git_branch"
    
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
        echo "INFO: Starting install blog..."
        install_blog ${dir_branch} ${git_branch}      
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
    wp_config_file="$server_dir/web/config.local.php"
    if [ -f "$script_dir/config/blog-config.php" ]; then
        cp "$script_dir/config/blog-config.php" $wp_config_file
    else
        echo "ERROR: blog-config.php is not exist."        
    fi

    echo "INFO: Creating .htaccess file for Blog app"
    if [ -f "$script_dir/config/blog-htaccess" ]; then
        cp "$script_dir/config/blog-htaccess" "$server_dir/web/.htaccess"
    else
        echo "ERROR: api-htaccess is not exist."  
    fi

    header_file="$server_dir/web/wp-content/themes/braxton/header.php"
    echo "INFO: update /blog/web/wp-content/themes/braxton/header.php file"
    sed -i "s/www.fabfitfun.com/dev.shop.fffdev.com/" ${header_file} 

    sed -i "s@Alias /magazine.*@Alias /magazine $server_dir/web@" ${shop_vhost_file}
    sed -i "s@Alias /magazine.*@Alias /magazine $server_dir/web@" ${shop_ssl_vhost_file}

    service apache2 reload
    service apache2 restart   
 
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

#!/bin/bash
jenkins_workspace="/var/lib/jenkins/workspace/test/"
apache_vhost_dir="/etc/apache2/sites-available/"
reponame="shop"
shop_db="ssoblog"
core_db="ebdb"



#Get parameter from command line
#Ex: ./clean-shop-fff.sh -b <git_branch_name> 
opt=$1
branch_param=$2

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

    if [ ! -n "$git_branch" ]; then
        echo "This is not merge! Do nothing!";
        exit 1;
    fi

    # Convert upper case to lower case
    git_branch_lower=$(echo "$git_branch" | tr '[:upper:]' '[:lower:]')
    echo "INFO: trigger branch: $git_branch_lower"

    # replace / by _
    project_name=$(echo $git_branch_lower | sed 's@/@_@g')
    # replace - by _
    project_name=$(echo $project_name | sed 's@-@_@g')
    echo "INFO Project-Name: $project_name"

    

}

remove_virtual_host(){
    a2ensite "$1.${reponame}.conf"
    a2ensite "$1.${reponame}-ssl.conf"
    apache_vhost_file="${apache_vhost_dir}$1.${reponame}.conf"
    apache_vhost_ssl_file="${apache_vhost_dir}$1.${reponame}-ssl.conf"

    echo "INFO: Deleting $apache_vhost_file"
}

get_branch_name(){
    cd $jenkins_workspace
    # Get the SHA of the checked out commit
    sha=$(git rev-parse HEAD)

    # get the last message when dev branch is submitted
    message=$( git show ${sha}  --pretty=oneline --abbrev-commit )

    # get branch-name that is merged to dev 
    if [[ $message == *"Merge pull request"* ]]; then
        branch_name=$( echo $message | awk '{ print $NF }' )
        # remove "fabfitfun/" out of branch name
        branch_name=$(echo $branch_name | sed 's@fabfitfun/@@')
    fi

    echo "$branch_name"
}

main
exit 0

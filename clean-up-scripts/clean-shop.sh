#!/bin/bash

#The dev server public ip
dev_server_ip="76.80.27.12"
domain="fffdev.com"
hosted_zone_id="Z1986QIYBBYSUJ"

www_dir="/var/www/html/"
jenkins_workspace="/var/lib/jenkins/workspace/Clean-Shop/"
sites_available="/etc/apache2/sites-available/"
sites_enabled="/etc/apache2/sites-enabled/"
reponame="shop"
shop_db="ssoblog"
core_db="ebdb"
db_passwd="vVDMGFJFQtaDxHWLhA96BFW4"


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
	
	shop_db_name="${project_name}_${shop_db}"
    core_db_name="${project_name}_${core_db}"
	domain_name="${project_name}.${reponame}.${domain}"
	
	remove_virtual_host ${project_name}
    remove_route53_record_set ${domain_name}
	remove_database ${shop_db_name} ${core_db_name}
	remove_root_dir ${project_name}
}

remove_virtual_host(){    
    sites_available_file="${sites_available}$1.${reponame}.conf"
    sites_available_ssl_file="${sites_available}$1.${reponame}-ssl.conf"
	sites_enabled_file="${sites_enabled}$1.${reponame}.conf"
    sites_enabled_ssl_file="${sites_enabled}$1.${reponame}-ssl.conf"
	

    echo "INFO: Deleting $sites_available_file"
	rm $sites_available_file
	rm $sites_enabled_file
	
	echo "INFO: Deleting $sites_available_ssl_file"
	rm $sites_available_ssl_file
	rm $sites_enabled_ssl_file
	
	service apache2 reload
}

remove_route53_record_set(){
    json_request='{
          "Comment": "Create a batch of A record sets",
          "Changes": [
            {
              "Action": "DELETE",
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
    echo "INFO: Remove route53 record set: domain-name=$1"
	aws route53 change-resource-record-sets  --hosted-zone-id $hosted_zone_id --change-batch "$json_request"
}

remove_database(){
    echo "INFO: DROP $1 database..."
    echo "DROP DATABASE IF EXISTS $1" | mysql -u root --password=${db_passwd}
	
	echo "INFO: DROP $2 database..."
    echo "DROP DATABASE IF EXISTS $2" | mysql -u root --password=${db_passwd}
}

remove_root_dir(){
    root_dir="${www_dir}$1.${reponame}"
	echo "INFO: remove directory $root_dir"
	rm -r $root_dir
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

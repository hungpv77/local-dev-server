#!/bin/bash

echo "CREATE DATABASE IF NOT EXISTS ebdb" | mysql -u root --password=vVDMGFJFQtaDxHWLhA96BFW4
echo "Importing ebdb data from dev-home db to localhost...."
mysqldump -h dev-home.cylgtp3yvrpn.us-east-1.rds.amazonaws.com -P 3306 -u masterusr28 -punwPtBLX8a7gHVYD ebdb | mysql -u root -pvVDMGFJFQtaDxHWLhA96BFW4 -h localhost -P 3306 -C ebdb
echo "CREATE DATABASE IF NOT EXISTS ssoblog" | mysql -u root --password=vVDMGFJFQtaDxHWLhA96BFW4
echo "Importing ssoblog data from dev-home db to localhost...."
mysqldump -h dev-home.cylgtp3yvrpn.us-east-1.rds.amazonaws.com -P 3306 -u masterusr28 -punwPtBLX8a7gHVYD ssoblog | mysql -u root -pvVDMGFJFQtaDxHWLhA96BFW4 -h localhost -P 3306 -C ssoblog	
#!/bin/bash
server_name="dev.shop.fffdev.com"
dev_server_ip="12.181.78.100"
hosted_zone_id="Z1986QIYBBYSUJ"

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
echo $json_request
echo "Calling API..."        
aws route53 change-resource-record-sets  --hosted-zone-id $hosted_zone_id --change-batch "$json_request"
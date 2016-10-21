#!/bin/bash
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

echo "Configuring " 
echo "[default]
aws_access_key_id = AKIAI6TJJYARA7CPRIXA
aws_secret_access_key = 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" | tee ~/.aws/credentials

echo "[default]
output = json
region = us-east-1" | tee ~/.aws/config
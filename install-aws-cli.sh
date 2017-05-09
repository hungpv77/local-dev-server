#!/bin/bash
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

echo "Configuring " 
echo "[default]
aws_access_key_id = AKIAI7KBU5P2IFB5VT6A
aws_secret_access_key = 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" | tee ~/.aws/credentials

echo "[default]
output = json
region = us-east-1" | tee ~/.aws/config
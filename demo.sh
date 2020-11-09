#!/bin/bash
set -e
start=$SECONDS
terraform init
terraform fmt
terraform validate
terraform plan
# apply
read -p "Press enter to continue"
terraform apply --auto-approve
duration=$(( SECONDS - start ))
echo "Operation took $duration seconds"

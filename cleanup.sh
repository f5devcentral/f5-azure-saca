#!/bin/bash
echo "destroying demo"
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    terraform destroy --auto-approve
    while [ $? -ne 0 ]; do
        terraform destroy --auto-approve
    done
else
    echo "canceling"
fi

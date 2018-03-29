#!/bin/bash
cd $HOME/f5-azure-saca
virtualenv venv
source venv/bin/activate
pip install ansible==2.4.3
pip install f5-sdk bigsuds netaddr deepdiff
pip install ansible[azure]
./gen_env.py > env.sh
source env.sh

#env
ansible-playbook deploy.yaml
ansible-playbook setup.yaml
ansible-playbook  -i ./azure_rm.py -e ansible_ssh_pass="{{lookup('file','.password.txt')|b64decode }}" update-vip-udr.yaml
commands=`python grab_vars.py --debug|grep -E "az network vnet subnet update"`
echo -e "$commands"
sh -c "$commands"

# in case failover script runs before getting replaced
az network nic update  -g ${AZURE_RESOURCE_GROUP}_F5_External  -n ${f5_unique_short_name}-ext0 --ip-forwarding true
az network nic update  -g ${AZURE_RESOURCE_GROUP}_F5_External  -n ${f5_unique_short_name}-ext1 --ip-forwarding true
az network nic update  -g ${AZURE_RESOURCE_GROUP}_F5_Internal  -n ${f5_unique_short_name2}-ext0 --ip-forwarding true
az network nic update  -g ${AZURE_RESOURCE_GROUP}_F5_Internal  -n ${f5_unique_short_name2}-ext1 --ip-forwarding true


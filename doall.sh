#!/bin/bash
cd $HOME/f5-azure-saca
./gen_env.py > env.sh
source env.sh
#env
ansible-playbook deploy.yaml
ansible-playbook setup.yaml
ansible-playbook  -i ./azure_rm.py -e ansible_ssh_pass="{{lookup('file','.password.txt')|b64decode }}" update-vip-udr.yaml
commands=`python grab_vars.py --debug|grep -E "az network vnet subnet update"`
echo -e "$commands"
sh -c "$commands"

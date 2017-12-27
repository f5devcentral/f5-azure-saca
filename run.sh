ansible-playbook setup.yaml
ansible-playbook  -i ./azure_rm.py -e ansible_ssh_pass=$f5_password update-vip-udr.yaml


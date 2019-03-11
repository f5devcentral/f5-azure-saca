ansible-playbook deploy.yaml
ansible-playbook setup.yaml
ansible-playbook  -i ./azure_rm.py -e ansible_ssh_pass="{{lookup('file','.password.txt')|b64decode }}" update-vip-udr.yaml



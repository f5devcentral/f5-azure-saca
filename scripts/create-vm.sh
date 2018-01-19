az vm create --image rhel --resource-group ${AZURE_RESOURCE_GROUP}_IL5-1 --name il5-mo-vm-1 --admin-username $f5_username --admin-password `base64 --decode .password.txt` --authentication-type password --vnet-name IL5MissionOwner1VNet --subnet ProductionSubnet --public-ip-address "" --nsg "" --private-ip-address 10.0.0.4


#!/bin/bash
# Change Values in these Variables to match your environment!!!!!
IL5MissionOwnerRGName='IL5MissionOwner1RG'
location='usdodeast'
SCCAinfrastructureRGname='SCCAinfrastructureRG'
SCCAinfrastructureVNetName='VDSS_VNet'
F5_Ext_Trust_RouteTableName='F5_Ext_Trust_RouteTable'
IPS_Trust_RouteTableName='IPS_Trust_RouteTable'
Internal_Subnets_RouteTableName='Internal_Subnets_RouteTable'
IPSUntrustedIP='192.168.2.5'
F5IntUntrustedIP='192.168.4.5'
F5IntTrustedIP='192.168.5.5'
IL5MissionOwnerVNetName='IL5MissionOwner1VNet'
IL5MissionOwnerVNetPrefix='10.0.0.0/22'
IL5MissionOwnerSubnet1Name='ProductionSubnet'
IL5MissionOwnerSubnet1Prefix='10.0.0.0/24'
RouteToIL5MissionOwnerName='ToIL5MissionOwner'

# These Variables will be used in the deployment tasks below... Don't change!!!
SCCAvnet=$(az network vnet show -g $SCCAinfrastructureRGname -n $SCCAinfrastructureVNetName --query id|sed  s/\"//g)
F5extTrustRouteTable=$(az network route-table show -g $SCCAinfrastructureRGname -n $F5_Ext_Trust_RouteTableName --query id|sed  s/\"//g)
IPSTrustRouteTable=$(az network route-table show -g $SCCAinfrastructureRGname -n $IPS_Trust_RouteTableName --query id|sed  s/\"//g)
InternalSubnetsRouteTable=$(az network route-table show -g $SCCAinfrastructureRGname -n $Internal_Subnets_RouteTableName --query id|sed  s/\"//g)

# Create the MissionOwner resource group.
az group create --location $location -n $IL5MissionOwnerRGName

# Create IL5 VNet.
az network vnet create -l $location -g $IL5MissionOwnerRGName -n $IL5MissionOwnerVNetName --address-prefixes $IL5MissionOwnerVNetPrefix

#Set IL5 VNet Variable
IL5vNet=$(az network vnet show -g $IL5MissionOwnerRGName  -n $IL5MissionOwnerVNetName --query id|sed  s/\"//g)

#Create Subnet in IL5 VNet and assign Internal_Subnets_RouteTable
echo "Create Subnet in IL5 VNet and assign Internal_Subnets_RouteTable"
az network vnet subnet create -n $IL5MissionOwnerSubnet1Name --address-prefix $IL5MissionOwnerSubnet1Prefix -g $IL5MissionOwnerRGName --vnet-name $IL5MissionOwnerVNetName --route-table $Internal_Subnets_RouteTableName

# Peer VNet1 to VNet2.
echo "Peer VNet1 to VNet2."
az network vnet peering create -n VDSStoIL5MissionOWner \
     --remote-vnet-id $IL5vNet \
     --resource-group $SCCAinfrastructureRGname \
     --vnet-name $SCCAinfrastructureVNetName

# Peer VNet2 to VNet1.
echo "Peer VNet2 to VNet1."
az network vnet peering create -n IL5MissionOwnerToVDSS \
     --remote-vnet-id $SCCAvnet \
     --resource-group $IL5MissionOwnerRGName \
     --vnet-name $IL5MissionOwnerVNetName


#Add IL5MO Route to F5_Ext_Trust_RouteTable
echo "Add IL5MO Route to F5_Ext_Trust_RouteTable"
az network route-table route create --address-prefix $IL5MissionOwnerVNetPrefix   \
   --name $RouteToIL5MissionOwnerName \
   --next-hop-type VirtualAppliance \
   --next-hop-ip-address $IPSUntrustedIP \
   --resource-group $SCCAinfrastructureRGname \
   --route-table-name $F5_Ext_Trust_RouteTableName

#Add IL5MO Route to IPS_Trust_RouteTable
echo "Add IL5MO Route to IPS_Trust_RouteTable"
az network route-table route create --address-prefix $IL5MissionOwnerVNetPrefix   \
   --name $RouteToIL5MissionOwnerName \
   --next-hop-type VirtualAppliance \
   --next-hop-ip-address $F5IntUntrustedIP \
   --resource-group $SCCAinfrastructureRGname \
   --route-table-name $IPS_Trust_RouteTableName
#Add IL5MO Route to Internal_Subnets_RouteTable
echo "Add IL5MO Route to Internal_Subnets_RouteTable"
az network route-table route create --address-prefix $IL5MissionOwnerVNetPrefix   \
   --name $RouteToIL5MissionOwnerName \
   --next-hop-type VirtualAppliance \
   --next-hop-ip-address $F5IntUntrustedIP \
   --resource-group $SCCAinfrastructureRGname \
   --route-table-name $Internal_Subnets_RouteTableName

                    

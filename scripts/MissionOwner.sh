#!/bin/bash
# Change Values in these Variables to match your environment!!!!!
IL5MissionOwnerRGName="${AZURE_RESOURCE_GROUP}_IL5-1"
location=$location
SCCAinfrastructureRGname="$AZURE_RESOURCE_GROUP"
SCCAinfrastructureVNetName='VDSS_VNet'
F5_Ext_Trust_RouteTableName='F5_Ext_Trust_RouteTable'
IPS_Trust_RouteTableName='IPS_Trust_RouteTable'
Internal_Subnets_RouteTableName='Internal_Subnets_RouteTable'
IPSUntrustedIP='192.168.2.5'
#F5IntUntrustedIP='192.168.4.5'
F5IntUntrustedIP=$(az network route-table route show -g $SCCAinfrastructureRGname --route-table-name $IPS_Trust_RouteTableName --name RouteToManagement --query "nextHopIpAddress"|sed  s/\"//g)
#F5IntTrustedIP='192.168.5.5'
F5IntTrustedIP=$(az network route-table route show -g $SCCAinfrastructureRGname --route-table-name $Internal_Subnets_RouteTableName --name RouteToInternet --query "nextHopIpAddress"|sed  s/\"//g)
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

case $1 in

    create) echo "Creating"
	    # Create the MissionOwner resource group.
	    az group create --location $location -n $IL5MissionOwnerRGName

	    # Create IL5 VNet.
	    az network vnet create -l $location -g $IL5MissionOwnerRGName -n $IL5MissionOwnerVNetName --address-prefixes $IL5MissionOwnerVNetPrefix

	    #Set IL5 VNet Variable
	    IL5vNet=$(az network vnet show -g $IL5MissionOwnerRGName  -n $IL5MissionOwnerVNetName --query id|sed  s/\"//g)

	    #Create Subnet in IL5 VNet and assign Internal_Subnets_RouteTable
	    echo "Create Subnet in IL5 VNet and assign Internal_Subnets_RouteTable"
	    az network vnet subnet create -n $IL5MissionOwnerSubnet1Name --address-prefix $IL5MissionOwnerSubnet1Prefix -g $IL5MissionOwnerRGName --vnet-name $IL5MissionOwnerVNetName --route-table $InternalSubnetsRouteTable

	    # Peer VNet1 to VNet2.
	    echo "Peer VNet1 to VNet2."
	    az network vnet peering create -n VDSStoIL5MissionOwner \
	       --remote-vnet-id $IL5vNet \
	       --resource-group $SCCAinfrastructureRGname \
	       --vnet-name $SCCAinfrastructureVNetName \
	       --allow-vnet-access 

	    # Peer VNet2 to VNet1.
	    echo "Peer VNet2 to VNet1."
	    az network vnet peering create -n IL5MissionOwnerToVDSS \
	       --remote-vnet-id $SCCAvnet \
	       --resource-group $IL5MissionOwnerRGName \
	       --vnet-name $IL5MissionOwnerVNetName \
	       --allow-vnet-access \
	       --allow-forwarded-traffic


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
	       --next-hop-ip-address $F5IntTrustedIP \
	       --resource-group $SCCAinfrastructureRGname \
	       --route-table-name $Internal_Subnets_RouteTableName
	    az network public-ip create  -g ${SCCAinfrastructureRGname}_F5_External -n f5-alb-ext-pip2 --allocation-method static
	    az network lb frontend-ip create --name loadBalancerFrontEnd2 --lb-name f5-ext-alb -g ${SCCAinfrastructureRGname}_F5_External  --public-ip-address f5-alb-ext-pip2

	    az network lb rule create --backend-port 80 --frontend-port 80  --lb-name f5-ext-alb  -g ${SCCAinfrastructureRGname}_F5_External  --name mo_http_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd2 --probe-name is_alive

            az network lb rule create --backend-port 443 --frontend-port 443  --lb-name f5-ext-alb  -g ${SCCAinfrastructureRGname}_F5_External  --name mo_https_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd2 --probe-name is_alive


    ;;
    delete) echo "Deleting"
	    #Delete IL5MO Route to F5_Ext_Trust_RouteTable
	    echo "Delete IL5MO Route to F5_Ext_Trust_RouteTable"
	    az network route-table route delete \
	       --name $RouteToIL5MissionOwnerName \
	       --resource-group $SCCAinfrastructureRGname \
	       --route-table-name $F5_Ext_Trust_RouteTableName

	    #Delete IL5MO Route to IPS_Trust_RouteTable
	    echo "Delete IL5MO Route to IPS_Trust_RouteTable"
	    az network route-table route delete \
	       --name $RouteToIL5MissionOwnerName \
	       --resource-group $SCCAinfrastructureRGname \
	       --route-table-name $IPS_Trust_RouteTableName
	    #Delete IL5MO Route to Internal_Subnets_RouteTable
	    echo "Delete IL5MO Route to Internal_Subnets_RouteTable"
	    az network route-table route delete \
	       --name $RouteToIL5MissionOwnerName \
	       --resource-group $SCCAinfrastructureRGname \
	       --route-table-name $Internal_Subnets_RouteTableName
	    # Delete VNet peering
	    echo "Delete VNet Peering"
	    az network vnet peering delete -n VDSStoIL5MissionOwner \
	       --resource-group $SCCAinfrastructureRGname \
	       --vnet-name $SCCAinfrastructureVNetName

	    echo "delete rules"
	    az network lb rule delete --lb-name f5-ext-alb  -g ${SCCAinfrastructureRGname}_F5_External  --name mo_http_vs
	    az network lb rule delete --lb-name f5-ext-alb  -g ${SCCAinfrastructureRGname}_F5_External  --name mo_https_vs
	    echo "delete frontend"	    
	    az network lb frontend-ip delete --name loadBalancerFrontEnd2 --lb-name f5-ext-alb -g ${SCCAinfrastructureRGname}_F5_External
	    # Delete pip
	    echo "delete pip"
	    az network public-ip delete  -g ${SCCAinfrastructureRGname}_F5_External -n f5-alb-ext-pip2	    
	    # Delete Resource Group
	    echo "delete group"
	    az group delete --y --name $IL5MissionOwnerRGName --no-wait
	    
	    ;;
    *)      echo "Invalid option"
	    ;;
	    esac
exit


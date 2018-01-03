#!/usr/bin/env python
from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.resource import ResourceManagementClient

from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource.resources.models import DeploymentMode
from azure.mgmt.loganalytics import LogAnalyticsManagementClient
from msrestazure.azure_cloud import AZURE_US_GOV_CLOUD
from optparse import OptionParser

parser = OptionParser()
parser.add_option('--action',help="external|internal|complete")
parser.add_option('--debug',action="store_true")
parser.add_option('--private',action="store_true")
(options, args) = parser.parse_args()

import os
import pprint
import re
import sys
import json
import time

from netaddr import IPNetwork, IPAddress

LOG_PROFILE="OMS.app/OMS_remote_logging"
#LOG_PROFILE="local-afm-log"

def get_ips(resource_group, instanceName):
    vm = compute_client.virtual_machines.get(resource_group,instanceName , expand='instanceview')
    vm_nic = vm.network_profile.network_interfaces[0].id.split('/')[-1]
    vm_ip =  IPAddress(network_client.network_interfaces.get(resource_group,vm_nic).ip_configurations[0].private_ip_address)
    if network_client.network_interfaces.get(resource_group,vm_nic).ip_configurations[0].public_ip_address:
        pip_name = network_client.network_interfaces.get(resource_group,vm_nic).ip_configurations[0].public_ip_address.id.split('/')[-1]
        pip = network_client.public_ip_addresses.get(resource_group,pip_name)
        if pip.dns_settings:
            return (vm_ip, IPAddress(pip.ip_address), pip.dns_settings.fqdn)
        else:
            return (vm_ip, IPAddress(pip.ip_address), None)
    else:
        return (vm_ip, None, None)

def get_ext_ips(resource_group, instanceName):
    vm = compute_client.virtual_machines.get(resource_group,instanceName , expand='instanceview')
    vm_nic = vm.network_profile.network_interfaces[1].id.split('/')[-1]
    vm_ip =  IPAddress(network_client.network_interfaces.get(resource_group,vm_nic).ip_configurations[0].private_ip_address)
    if network_client.network_interfaces.get(resource_group,vm_nic).ip_configurations[0].public_ip_address:
        pip_name = network_client.network_interfaces.get(resource_group,vm_nic).ip_configurations[0].public_ip_address.id.split('/')[-1]
        pip = network_client.public_ip_addresses.get(resource_group,pip_name)
        return (vm_ip, IPAddress(pip.ip_address))
    else:
        return (vm_ip, None)

#def enable_ip_forward(resource_group, instanceName):

def get_pip(resource_group, pip_name):
    pip = network_client.public_ip_addresses.get(resource_group,pip_name)
    if pip.dns_settings:
        return (IPAddress(pip.ip_address), pip.dns_settings.fqdn)
    else:
        return (IPAddress(pip.ip_address), None)

subnet_re=re.compile('/\d\d?$')
ipaddr_re=re.compile('\d+\.\d+\.\d+\.\d+')
subscription_id=os.environ['AZURE_SUBSCRIPTION_ID']
credentials = ServicePrincipalCredentials(
    client_id=os.environ['AZURE_CLIENT_ID'],
    secret=os.environ['AZURE_SECRET'],
    tenant=os.environ['AZURE_TENANT'],
    cloud_environment=AZURE_US_GOV_CLOUD
)
resource_group = os.environ['AZURE_RESOURCE_GROUP']
f5_ext_resource_group = "%s_F5_External" %(resource_group)
f5_int_resource_group = "%s_F5_Internal" %(resource_group)
resource_client = ResourceManagementClient(credentials, subscription_id, base_url=AZURE_US_GOV_CLOUD.endpoints.resource_manager)
compute_client = ComputeManagementClient(credentials, subscription_id, base_url=AZURE_US_GOV_CLOUD.endpoints.resource_manager)
network_client = NetworkManagementClient(credentials, subscription_id, base_url=AZURE_US_GOV_CLOUD.endpoints.resource_manager)
loganalytics_client = LogAnalyticsManagementClient(credentials, subscription_id, base_url=AZURE_US_GOV_CLOUD.endpoints.resource_manager)
parameters = None

f5_password = os.environ['f5_password']
f5_unique_short_name = os.environ['f5_unique_short_name']
f5_unique_short_name2 = os.environ['f5_unique_short_name2']

f5_license_key_1 = os.environ['f5_license_key_1']
f5_license_key_2 = os.environ['f5_license_key_2']
f5_license_key_3 = os.environ['f5_license_key_3']
f5_license_key_4 = os.environ['f5_license_key_4']

client_id=os.environ['AZURE_CLIENT_ID']
client_secret=os.environ['AZURE_SECRET']
tenant_id=os.environ['AZURE_TENANT']
cloud_environment=AZURE_US_GOV_CLOUD

for deployment in resource_client.deployments.list_by_resource_group(resource_group):
#    if deployment.name != 'Microsoft.Template':
#        continue
#    data = deployment.as_dict()
#    print deployment.name
#    print data
    if "f5_Ext_Untrusted_SubnetName" not in deployment.properties.parameters.keys():
        continue

    deployment.properties.parameters
    parameters = dict([(x,deployment.properties.parameters[x].get('value')) for x in deployment.properties.parameters])
    for (k,v) in parameters.items():
        if v and subnet_re.search(v):
            parameters[k] = IPNetwork(v)
        elif v and ipaddr_re.search(v):
            parameters[k] = IPAddress(v)
if options.debug:
    pprint.pprint(parameters)

jumphost_ip =  get_ips(resource_group, parameters['vdssJumpBoxName'])[0]
jumphostlinux_ip =  get_ips(resource_group, parameters['vdssJumpBoxLinuxName'])[0]

mgmt_start_ip = IPAddress(parameters['management_SubnetPrefix'].first+10)

#if not resource_client.resource_groups.check_existence(f5_ext_resource_group):
if options.action == "external":
  ext_parameters = {
      "adminUsername": parameters['vdssJumpBoxAdminUserName'],
      "adminPassword": f5_password,
      "dnsLabel": f5_unique_short_name,
      "instanceName": f5_unique_short_name,
      "imageName":"Best",
      "bigIpVersion":"13.0.0300",
      "licenseKey1": f5_license_key_1,
      "licenseKey2": f5_license_key_2,
      "numberOfExternalIps": 0,
      "vnetName": parameters['vnetName'],
      "vnetResourceGroupName": resource_group,
      "mgmtSubnetName": parameters['management_SubnetName'],
      "mgmtIpAddressRangeStart":  str(mgmt_start_ip + 1),
      "externalSubnetName": parameters['f5_Ext_Untrusted_SubnetName'],
      "externalIpSelfAddressRangeStart":  str(parameters['f5_Ext_Untrusted_IP'] - 3),
      "externalIpAddressRangeStart": str(parameters['f5_Ext_Untrusted_IP'] - 1),
      "internalSubnetName": parameters['f5_Ext_Trusted_SubnetName'],
      "internalIpAddressRangeStart":  str(parameters['f5_Ext_Trusted_IP'] - 1),
      "tenantId": tenant_id,
      "clientId": client_id,
      "servicePrincipalSecret": client_secret,
      "managedRoutes": "0.0.0.0/0",
      "routeTableTag": "%sRouteTag" %(f5_unique_short_name),
      "ntpServer": "0.pool.ntp.org",
      "timeZone": "UTC",
      "restrictedSrcAddress":  "*",
      "allowUsageAnalytics": "No"
  }


  send_parameters = {k: {'value': v} for k, v in ext_parameters.items()}
  print json.dumps(send_parameters)
  sys.exit(0)
if options.action == "internal":
#                                               deployment_properties)
  int_parameters = {
      "adminUsername": parameters['vdssJumpBoxAdminUserName'],
      "adminPassword": f5_password,
      "dnsLabel": f5_unique_short_name2,
      "instanceName": f5_unique_short_name2,
      "imageName":"Best",
      "bigIpVersion":"13.0.0300",
      "licenseKey1": f5_license_key_3,
      "licenseKey2": f5_license_key_4,
      "numberOfExternalIps": 0,
      "vnetName": parameters['vnetName'],
      "vnetResourceGroupName": resource_group,
      "mgmtSubnetName": parameters['management_SubnetName'],
      "mgmtIpAddressRangeStart":  str(mgmt_start_ip + 3),
      "externalSubnetName": parameters['f5_Int_Untrusted_SubnetName'],
      "externalIpSelfAddressRangeStart":  str(parameters['f5_Int_Untrusted_IP'] - 3),
      "externalIpAddressRangeStart": str(parameters['f5_Int_Untrusted_IP'] - 1),
      "internalSubnetName": parameters['f5_Int_Trusted_SubnetName'],
      "internalIpAddressRangeStart":  str(parameters['f5_Int_Trusted_IP'] - 1),
      "tenantId": tenant_id,
      "clientId": client_id,
      "servicePrincipalSecret": client_secret,
      "managedRoutes": "0.0.0.0/0,%s,%s,%s,%s" %(str(parameters['management_SubnetPrefix']),
                                                 str(parameters['vdmS_SubnetPrefix']),
                                                 parameters['f5_Ext_Untrusted_SubnetPrefix'],
                                                 parameters['f5_Ext_Trusted_SubnetPrefix']),
      "routeTableTag": "%sRouteTag" %(f5_unique_short_name2),
      "ntpServer": "0.pool.ntp.org",
      "timeZone": "UTC",
      "restrictedSrcAddress":  "*",
      "allowUsageAnalytics": "No"
  }

  send_parameters = {k: {'value': v} for k, v in int_parameters.items()}
  print json.dumps(send_parameters)
  sys.exit(0)

f5_ext = None

waiting = True
while waiting:

    for deployment in resource_client.deployments.list_by_resource_group(f5_ext_resource_group):
        data = deployment.as_dict()
        if 'externalIpSelfAddressRangeStart' not in deployment.properties.parameters:
            continue
        # print data['name']
        # print data['properties']['provisioning_state']
        # print data['properties'].keys()
        # print deployment.properties.parameters
        if data['properties']['provisioning_state'] == 'Running':
        #if data['properties']['provisioning_state'] == 'Succeeded':
            waiting = True
        else:
            waiting = False
        f5_ext = dict([(x,deployment.properties.parameters[x].get('value')) for x in deployment.properties.parameters])
        for (k,v) in f5_ext.items():
            if not isinstance(v,str):
                continue
            if v and subnet_re.search(v):
                f5_ext[k] = IPNetwork(v)
            elif v and ipaddr_re.search(v):
                f5_ext[k] = IPAddress(v)
    if waiting:
        # print 'waiting'
        time.sleep(30)

#pprint.pprint(f5_ext)

if options.debug:
    pprint.pprint(f5_ext)

if not resource_client.resource_groups.check_existence(f5_int_resource_group):

  sys.exit(0)

f5_int = None
waiting = True

while waiting:

    for deployment in resource_client.deployments.list_by_resource_group(f5_int_resource_group):
        if 'externalIpSelfAddressRangeStart' not in deployment.properties.parameters:
            continue

        data = deployment.as_dict()


        deployment.properties.parameters
        if data['properties']['provisioning_state'] == 'Running':
        #if data['properties']['provisioning_state'] == 'Succeeded':
            waiting = True
        else:
            waiting = False

        f5_int = dict([(x,deployment.properties.parameters[x].get('value')) for x in deployment.properties.parameters])
        for (k,v) in f5_int.items():
            if not isinstance(v,str):
                continue
            if v and subnet_re.search(v):
                f5_int[k] = IPNetwork(v)
            elif v and ipaddr_re.search(v):
                f5_int[k] = IPAddress(v)
    if waiting:
        # print 'waiting'
        time.sleep(30)

if options.debug:
    pprint.pprint(f5_int)


#print "az vm show --name %s --resource-group \"%s\"  -d   --query \"privateIps\" -d" %(parameters['jumpBoxName'],resource_group)
vm = compute_client.virtual_machines.get(resource_group, parameters['vdssJumpBoxName'],expand='instanceview')
nic = vm.network_profile.network_interfaces[0].id.split('/')[-1]
jumphost_ip = IPAddress(network_client.network_interfaces.get(resource_group,nic).ip_configurations[0].private_ip_address)


(bigip_ext1_ip, bigip_ext1_pip, bigip_ext1_fqdn) = get_ips(f5_ext_resource_group, "%s-%s0" %(f5_ext['dnsLabel'], f5_ext['instanceName']))
(bigip_ext2_ip, bigip_ext2_pip, bigip_ext2_fqdn) = get_ips(f5_ext_resource_group, "%s-%s1" %(f5_ext['dnsLabel'], f5_ext['instanceName']))
# no pip
if not bigip_ext1_pip:
    bigip_ext1_pip = bigip_ext1_ip

if not bigip_ext2_pip:
    bigip_ext2_pip = bigip_ext2_ip


(bigip_int1_ip, bigip_int1_pip, bigip_int1_fqdn) = get_ips(f5_int_resource_group, "%s-%s0" %(f5_int['dnsLabel'], f5_int['instanceName']))
(bigip_int2_ip, bigip_int2_pip, bigip_int2_fqdn) = get_ips(f5_int_resource_group, "%s-%s1" %(f5_int['dnsLabel'], f5_int['instanceName']))

if not bigip_int1_pip:
    bigip_int1_pip = bigip_int1_ip
if not bigip_int2_pip:
    bigip_int2_pip = bigip_int2_ip

(bigip_ext_ext1_ip, bigip_ext_ext1_pip) = get_ext_ips(f5_ext_resource_group, "%s-%s0" %(f5_ext['dnsLabel'], f5_ext['instanceName']))
(bigip_ext_ext2_ip, bigip_ext_ext2_pip) = get_ext_ips(f5_ext_resource_group, "%s-%s1" %(f5_ext['dnsLabel'], f5_ext['instanceName']))
(bigip_ext_int1_ip, bigip_ext_int1_pip) = get_ext_ips(f5_int_resource_group, "%s-%s0" %(f5_int['dnsLabel'], f5_int['instanceName']))
(bigip_ext_int2_ip, bigip_ext_int2_pip) = get_ext_ips(f5_int_resource_group, "%s-%s1" %(f5_int['dnsLabel'], f5_int['instanceName']))

#bigip_ext1 = IPAddress(parameters['management_SubnetPrefix'].first+10)
#bigip_ext2 = IPAddress(parameters['management_SubnetPrefix'].first+11)
#bigip_int1 = IPAddress(parameters['management_SubnetPrefix'].first+12)
#bigip_int2 = IPAddress(parameters['management_SubnetPrefix'].first+13)

external_pip = get_pip(resource_group+"_F5_External", "f5-alb-ext-pip0")
external_pip2 = get_pip(resource_group+"_F5_External", "f5-alb-ext-pip1")
#print external_pip

# add 2 for now, needs to be fixed
#external_vip =  parameters['f5_Ext_Untrusted_IP']
external_vip = str(external_pip[0])
external_vip2 = str(external_pip2[0])

subnet = network_client.subnets.get(resource_group,str(f5_ext["vnetName"]),str(f5_ext["externalSubnetName"]))
subnet.id
internalsubnet = network_client.subnets.get(resource_group,str(f5_int["vnetName"]),str(f5_int["externalSubnetName"]))
internalsubnet.id

#internal_vip =  parameters['f5_Int_Untrusted_IP']

internal_ext_gw = IPAddress(parameters['f5_Int_Untrusted_SubnetPrefix'].first+1)
internal_ext_gw = IPAddress(parameters['f5_Int_Untrusted_SubnetPrefix'].first+1)

output = {}
pools = []
pool_members = []
virtuals = []
if options.debug:
    print "### EXTERNAL F5 ###"
    print "# Routes"
    print "create /net route mgmt network %s gw %s" %(parameters['management_SubnetPrefix'], IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1))
    print "create /net route vdms network %s gw %s" %(parameters['vdmS_SubnetPrefix'], IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1))
    print "# MGMT Hosts"
    print "create /ltm pool jumpbox_rdp_pool members replace-all-with { %s:3389}" %(jumphost_ip)
    print "create /ltm pool jumpbox_rdp_pool members replace-all-with { %s:22}" %(jumphostlinux_ip)

#    print "create /ltm virtual jumpbox_rdp_vs destination %s:3389 profiles replace-all-with { loose_fastL4 } pool jumpbox_rdp_pool source-address-translation { type automap }" %(external_vip)
    print "create /ltm virtual jumpbox_rdp_local_vs destination %s:3389 profiles replace-all-with { loose_fastL4 } pool jumpbox_rdp_pool source-address-translation { type automap }" %(bigip_ext_ext1_ip)
    print "create /ltm virtual jumpbox_rdp_local_vs destination %s:3389 profiles replace-all-with { loose_fastL4 } pool jumpbox_rdp_pool source-address-translation { type automap }" %(bigip_ext_ext2_ip)
    print "create /ltm pool bigip_ext1_ssh_pool members replace-all-with { %s:22}" %(bigip_ext1_ip)
    print "create /ltm pool bigip_ext2_ssh_pool members replace-all-with { %s:22}" %(bigip_ext2_ip)
    print "create /ltm pool bigip_int1_ssh_pool members replace-all-with { %s:22}" %(bigip_int1_ip)
    print "create /ltm pool bigip_int2_ssh_pool members replace-all-with { %s:22}" %(bigip_int2_ip)

routes= [{ 'name': 'mgmt',
          'destination': str(parameters['management_SubnetPrefix']), 
          'gateway_address': str(IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1)), 
          'server': str(bigip_ext1_pip) },
         { 'name': 'vdms',
           'destination': str(parameters['vdmS_SubnetPrefix']), 
           'gateway_address': str(IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_ext1_pip) },
         { 'name': 'internalvips',
           'destination': str(parameters['f5_Int_Trusted_SubnetPrefix']), 
           'gateway_address': str(IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_ext1_pip) },
         { 'name': 'private10',
           'destination': '10.0.0.0/8',
           'gateway_address': str(IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_ext1_pip) },
         { 'name': 'private172',
           'destination': '172.16.0.0/12', 
           'gateway_address': str(IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_ext1_pip) },
         { 'name': 'private192',
           'destination': '192.168.0.0/16', 
           'gateway_address': str(IPAddress(parameters['f5_Ext_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_ext1_pip) }         
     ]
pools.append({'server': str(bigip_ext1_pip),
             'name': 'jumpbox_rdp_pool',
              'partition':'Common'})
pool_members.append({'server': str(bigip_ext1_pip),
              'pool': 'jumpbox_rdp_pool',
              'host': str(jumphost_ip),
              'name': str(jumphost_ip),
              'port': '3389'})

pools.append({'server': str(bigip_ext1_pip),
             'name': 'jumpbox_rdp_gw_pool',
              'partition':'Common'})
pool_members.append({'server': str(bigip_ext1_pip),
              'pool': 'jumpbox_rdp_gw_pool',
              'host': str(jumphost_ip),
              'name': str(jumphost_ip),
              'port': '443'})

pools.append({'server': str(bigip_ext1_pip),
             'name': 'jumpbox_ssh_pool',
              'partition':'Common'})
pool_members.append({'server': str(bigip_ext1_pip),
              'pool': 'jumpbox_ssh_pool',
              'host': str(jumphostlinux_ip),
              'name': str(jumphostlinux_ip),
              'port': '22'})

pools.append({'server': str(bigip_ext1_pip),
             'name': 'http_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
              'pool': 'http_pool',
              'host': str(jumphostlinux_ip),
              'name': str(jumphostlinux_ip),
              'port': '80'})

pools.append({'server': str(bigip_ext1_pip),
             'name': 'https_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
              'pool': 'https_pool',
              'host': str(jumphostlinux_ip),
              'name': str(jumphostlinux_ip),
              'port': '443'})


pools.append({'server': str(bigip_ext1_pip),
             'name': 'ssl_visible_http_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
              'pool': 'ssl_visible_http_pool',
              'host': str(parameters['f5_Int_Untrusted_IP']),
              'name': str(parameters['f5_Int_Untrusted_IP']),
              'port': '80'})



virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'jumpbox_rdp_vs',
                 'command': "create /ltm virtual jumpbox_rdp_vs destination %s:3389 profiles replace-all-with { loose_fastL4 } pool jumpbox_rdp_pool source-address-translation { type automap } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(external_vip, LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'jumpbox_ssh_vs',
                 'command': "create /ltm virtual jumpbox_ssh_vs destination %s:22 profiles replace-all-with { loose_fastL4 } pool jumpbox_ssh_pool source-address-translation { type automap } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(external_vip, LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'jumpbox_rdp_gw_vs',
                 'command': "create /ltm virtual jumpbox_rdp_gw_vs destination %s:443 profiles replace-all-with { loose_fastL4 } pool jumpbox_rdp_gw_pool source-address-translation { type automap } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(external_vip, LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'http_vs',
                 'command': "create /ltm virtual http_vs destination %s:80 profiles replace-all-with {  http } pool http_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(external_vip2, LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'ssl_visible_vs',
                 'command': "create /ltm virtual ssl_visible_vs destination %s:443 profiles replace-all-with { clientssl http } pool ssl_visible_http_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(external_vip2, LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'ssl_not_visible_vs',
                 'command': "create /ltm virtual ssl_not_visible_vs destination %s:8443 profiles replace-all-with { loose_fastL4 } pool https_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(external_vip2, LOG_PROFILE)})


virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'float_is_alive_vs',
                 'command': "create /ltm virtual float_is_alive_vs destination %s:80 profiles replace-all-with { http } rules { is_alive } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(parameters['f5_Ext_Untrusted_IP']), LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext1_pip),
                 'name':'is_alive_vs',
                 'command': "create /ltm virtual is_alive_vs destination %s:80 profiles replace-all-with { http } rules { virtual_is_alive } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(bigip_ext_ext1_ip), LOG_PROFILE)})

virtuals.append({'server': str(bigip_ext2_pip),
                 'name':'is_alive_vs',
                 'command': "create /ltm virtual is_alive_vs destination %s:80 profiles replace-all-with { http }  rules { virtual_is_alive } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(bigip_ext_ext2_ip), LOG_PROFILE)})

pools.append({'server': str(bigip_ext1_pip),
             'name': 'bigip_ext1_ssh_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
                     'pool': 'bigip_ext1_ssh_pool',
                     'host': str(bigip_ext1_ip),
                     'name': str(bigip_ext1_ip),
                     'port': '22'})

pools.append({'server': str(bigip_ext1_pip),
             'name': 'bigip_ext2_ssh_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
                     'pool': 'bigip_ext2_ssh_pool',
                     'host': str(bigip_ext2_ip),
                     'name': str(bigip_ext2_ip),
                     'port': '22'})


pools.append({'server': str(bigip_ext1_pip),
             'name': 'bigip_int1_ssh_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
                     'pool': 'bigip_int1_ssh_pool',
                     'host': str(bigip_int1_ip),
                     'name': str(bigip_int1_ip),
                     'port': '22'})



pools.append({'server': str(bigip_ext1_pip),
              'name': 'bigip_int2_ssh_pool',
              'partition':'Common'})

pool_members.append({'server': str(bigip_ext1_pip),
                     'pool': 'bigip_int2_ssh_pool',
                     'host': str(bigip_int2_ip),
                     'name': str(bigip_int2_ip),
                     'port': '22'})





#print "create /ltm pool external_snat_pool members replace-all-with { %s:0}" %(external_vip)

if options.debug:
    print "create /ltm virtual bigip1_ext1_ssh_vs destination %s:2200 profiles replace-all-with { loose_fastL4 } pool bigip_ext1_ssh_pool  fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)
    print "create /ltm virtual bigip1_ext2_ssh_vs destination %s:2201 profiles replace-all-with { loose_fastL4 } pool bigip_ext2_ssh_pool translate-address disabled translate-port disabled fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)
    print "create /ltm virtual bigip1_ext3_ssh_vs destination %s:2202 profiles replace-all-with { loose_fastL4 } pool bigip_ext3_ssh_pool  fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)
    print "create /ltm virtual bigip1_ext4_ssh_vs destination %s:2203 profiles replace-all-with { loose_fastL4 } pool bigip_ext4_ssh_pool  fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)

# virtuals.append({'server': str(bigip_ext1_pip),
#                  'name':'bigip_ext1_ssh_vs',
#                  'command': "create /ltm virtual bigip1_ext1_ssh_vs destination %s:2200 profiles replace-all-with { loose_fastL4 } pool bigip_ext1_ssh_pool  fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)})

# virtuals.append({'server': str(bigip_ext1_pip),
#                  'name':'bigip_ext2_ssh_vs',
#                  'command': "create /ltm virtual bigip1_ext2_ssh_vs destination %s:2201 profiles replace-all-with { loose_fastL4 } pool bigip_ext2_ssh_pool translate-address disabled translate-port disabled fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)})

# virtuals.append({'server': str(bigip_ext1_pip),
#                  'name':'bigip_int1_ssh_vs',
#                  'command': "create /ltm virtual bigip1_int1_ssh_vs destination %s:2202 profiles replace-all-with { loose_fastL4 } pool bigip_int1_ssh_pool  fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)})

# virtuals.append({'server': str(bigip_ext1_pip),
#                  'name':'bigip_int2_ssh_vs',
#                  'command': "create /ltm virtual bigip1_int2_ssh_vs destination %s:2203 profiles replace-all-with { loose_fastL4 } pool bigip_int2_ssh_pool  fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(external_vip)})

virtuals.append({'server': str(bigip_ext1_pip),
                  'name':'mgmt_outbound_vs',
                  'command':"create /ltm virtual mgmt_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } ip-forward fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }     source-address-translation { type automap  }" %(parameters['management_SubnetPrefix'], LOG_PROFILE)})
virtuals.append({'server': str(bigip_ext1_pip),
                  'name':'vdms_outbound_vs',
                  'command':"create /ltm virtual vdms_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } ip-forward fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s } source-address-translation { type automap }" %(parameters['vdmS_SubnetPrefix'], LOG_PROFILE)})
virtuals.append({'server': str(bigip_ext1_pip),
                  'name':'mo_outbound_vs',
                  'command':"create /ltm virtual vdms_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source 10.0.0.0/8 profiles replace-all-with { loose_fastL4 } ip-forward fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s } source-address-translation { type automap }" %(LOG_PROFILE) })


if options.debug:
    print "create /ltm virtual mgmt_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } ip-forward fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }     source-address-translation { type automap  }" %(parameters['management_SubnetPrefix'], LOG_PROFILE)
    print "create /ltm virtual vdms_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } ip-forward fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s } source-address-translation { type automap }" %(parameters['vdmS_SubnetPrefix'], LOG_PROFILE)

if options.action == "external_setup":
    ws = loganalytics_client.workspaces.get(resource_group,resource_group.replace('_','-') + '-oms') 
    keys = loganalytics_client.workspaces.get_shared_keys(resource_group,resource_group.replace('_','-') + '-oms') 
    output['oms'] = [{'customer_id':ws.customer_id,
                      'key':keys.primary_shared_key,
                      'server':str(bigip_ext1_pip)}]

    output['routes'] = routes
    output['pools'] = pools
    output['pool_members'] = pool_members
    output['virtuals'] = virtuals
    modules = []
    modules.append({'module':'afm',
                    'level':'nominal',
                    'server':str(bigip_ext1_pip)})
    modules.append({'module':'afm',
                    'level':'nominal',
                    'server':str(bigip_ext2_pip)})
    output['modules'] = modules

    output['irules'] = [{'name':'is_alive',
                         'content': "when HTTP_REQUEST {\n    HTTP::respond 200 content \"OK\"\n}\n",
                         'server':str(bigip_ext1_pip)},
                        {'name':'virtual_is_alive',
                         'content': "when CLIENT_ACCEPTED {\n    virtual float_is_alive_vs\n}\n",
                         'server':str(bigip_ext1_pip)}]
        
    commands = []
    commands.append({'check':'tmsh list /ltm profile fastl4 loose_fastL4',
                     'command':'tmsh create /ltm profile fastl4 loose_fastL4 defaults-from fastL4 loose-close enabled loose-initialization enabled idle-timeout 300 reset-on-timeout disabled',
                     'server':str(bigip_ext1_pip)})
    commands.append({'check':'tmsh list /security log profile local-afm-log',
                     'command':'tmsh create /security log profile local-afm-log { network replace-all-with { local-afm-log { publisher local-db-publisher filter { log-acl-match-accept enabled log-acl-match-drop enabled log-acl-match-reject enabled } } } }',
                     'server':str(bigip_ext1_pip)})
    commands.append({'check':'tmsh list /security firewall policy log_all_afm',
                     'command':'tmsh create /security firewall policy log_all_afm rules add { allow_all  { action accept log yes place-before first } deny_all { action reject log yes place-after allow_all  }}',
                     'server':str(bigip_ext1_pip)})

    commands.append({'check':'tmsh list /ltm virtual-address 0.0.0.0',
                     'command':'create /ltm virtual-address 0.0.0.0 traffic-group none',
                     'server':str(bigip_ext1_pip)})

    commands.append({'check':'tmsh list /ltm virtual-address %s' %(external_vip),
                     'command':'create /ltm virtual-address %s traffic-group none' %(external_vip),
                     'server':str(bigip_ext1_pip)})

    commands.append({'check':'tmsh list /ltm virtual-address %s' %(external_vip2),
                     'command':'create /ltm virtual-address %s traffic-group none' %(external_vip2),
                     'server':str(bigip_ext1_pip)})


    output['commands'] = commands

#    print json.dumps(output)
#    sys.exit(0)

if options.debug:
    print "\n\n### INTERNAL F5 ###"
#    print "create /net self self_2nic_float address %s/%s vlan external traffic-group traffic-group-1" %(internal_vip,parameters['f5_Int_Untrusted_SubnetPrefix'].prefixlen)
    print "create /ltm pool ext_gw_pool members replace-all-with { %s:0}" %(internal_ext_gw)
    print "create /ltm virtual mgmt_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } pool ext_gw_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(parameters['management_SubnetPrefix'])
    print "create /ltm virtual vdms_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } pool ext_gw_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { local-afm-log }" %(parameters['vdmS_SubnetPrefix'])


if options.action == "internal_setup":
    output = {}

    ws = loganalytics_client.workspaces.get(resource_group,resource_group.replace('_','-') + '-oms') 
    keys = loganalytics_client.workspaces.get_shared_keys(resource_group,resource_group.replace('_','-') + '-oms') 
    output['oms'] = [{'customer_id':ws.customer_id,
                      'key':keys.primary_shared_key,
                      'server':str(bigip_int1_pip)}]

    virtuals = []
    pools = []
    pool_members = []

    output['irules'] = [{'name':'is_alive',
                         'content': "when HTTP_REQUEST {\n    HTTP::respond 200 content \"OK\"\n}\n",
                         'server':str(bigip_int1_pip)},
                        {'name':'virtual_is_alive',
                         'content': "when CLIENT_ACCEPTED {\n    virtual float_is_alive_vs\n}\n",
                         'server':str(bigip_int1_pip)}]


    pools.append({'server': str(bigip_int1_pip),
                  'name': 'ext_gw_pool',
                  'partition':'Common'})

    pools.append({'server': str(bigip_int1_pip),
                  'name': 'https_pool',
                  'partition':'Common'})


    pool_members.append({'server': str(bigip_int1_pip),
                         'pool': 'ext_gw_pool',
                         'host': str(internal_ext_gw),
                         'name': str(internal_ext_gw),
                         'port': '0'})

    pool_members.append({'server': str(bigip_int1_pip),
                         'pool': 'https_pool',
                         'host': str(jumphostlinux_ip),
                         'name': str(jumphostlinux_ip),
                         'port': '443'})


    virtuals.append({'server': str(bigip_int1_pip),
                     'name':'mgmt_outbound_vs',
                     'command':"create /ltm virtual mgmt_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } pool ext_gw_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(parameters['management_SubnetPrefix'], LOG_PROFILE)})

    virtuals.append({'server': str(bigip_int1_pip),
                     'name':'vdms_outbound_vs',
                     'command':"create /ltm virtual vdms_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source %s profiles replace-all-with { loose_fastL4 } pool ext_gw_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(parameters['vdmS_SubnetPrefix'], LOG_PROFILE)})

    virtuals.append({'server': str(bigip_int1_pip),
                     'name':'mo_outbound_vs',
                     'command':"create /ltm virtual vdms_outbound_vs destination 0.0.0.0:0 mask 0.0.0.0 source 10.0.0.0/8 profiles replace-all-with { loose_fastL4 } pool ext_gw_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(LOG_PROFILE) })


    virtuals.append({'server': str(bigip_int1_pip),
                     'name':'forward_vs',
                     'command':"create /ltm virtual forward_vs destination 0.0.0.0:0 mask 0.0.0.0  profiles replace-all-with { loose_fastL4 } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(LOG_PROFILE) })

    virtuals.append({'server': str(bigip_int1_pip),
                     'name':'http_vs',
                     'command':"create /ltm virtual http_vs destination %s:80  profiles replace-all-with { http serverssl } pool https_pool fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(parameters['f5_Int_Untrusted_IP']), LOG_PROFILE)})

    virtuals.append({'server': str(bigip_int1_pip),
                 'name':'float_is_alive_vs',
                     'command': "create /ltm virtual float_is_alive_vs destination %s:9999 profiles replace-all-with { http } rules { is_alive } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(parameters['f5_Int_Untrusted_IP']-1), LOG_PROFILE)})

    virtuals.append({'server': str(bigip_int1_pip),
                 'name':'is_alive_vs',
                     'command': "create /ltm virtual is_alive_vs destination %s:80 profiles replace-all-with { http } rules { virtual_is_alive } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(bigip_ext_int1_ip), LOG_PROFILE)})

    virtuals.append({'server': str(bigip_int2_pip),
                 'name':'is_alive_vs',
                     'command': "create /ltm virtual is_alive_vs destination %s:80 profiles replace-all-with { http }  rules { virtual_is_alive } fw-enforced-policy log_all_afm security-log-profiles replace-all-with { %s }" %(str(bigip_ext_int2_ip), LOG_PROFILE)})




    # output['selfips'] = [{'name': 'self_2nic_float',
    #                      'address': str(internal_vip),
    #                      'netmask': str(parameters['f5_Int_Untrusted_SubnetPrefix'].netmask),
    #                      'vlan': 'external',
    #                      'traffic_group':'traffic-group-1',
    #                      'server': str(bigip_int1_pip),
    #                  }]
    output['selfips'] = []
    output['pools'] = pools
    output['pool_members'] = pool_members
    output['virtuals'] = virtuals

    routes= [
         { 'name': 'default',
           'destination': 'default',
           'gateway_address': str(IPAddress(parameters['f5_Int_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_int1_pip) },
        { 'name': 'exttrusted',
           'destination': str(parameters['f5_Ext_Trusted_SubnetPrefix']), 
           'gateway_address': str(IPAddress(parameters['f5_Int_Untrusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_int1_pip) },
         { 'name': 'private10',
           'destination': '10.0.0.0/8',
           'gateway_address': str(IPAddress(parameters['f5_Int_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_int1_pip) },
         { 'name': 'private172',
           'destination': '172.16.0.0/12', 
           'gateway_address': str(IPAddress(parameters['f5_Int_Trusted_SubnetPrefix'].first+1)), 
           'server': str(bigip_int1_pip) }

     ]

    output['routes'] = routes
    modules = []
    modules.append({'module':'afm',
                    'level':'nominal',
                    'server':str(bigip_int1_pip)})
    modules.append({'module':'afm',
                    'level':'nominal',
                    'server':str(bigip_int2_pip)})

    modules.append({'module':'asm',
                    'level':'nominal',
                    'server':str(bigip_int1_pip)})
    modules.append({'module':'asm',
                    'level':'nominal',
                    'server':str(bigip_int2_pip)})


    modules.append({'module':'apm',
                    'level':'nominal',
                    'server':str(bigip_int1_pip)})
    modules.append({'module':'apm',
                    'level':'nominal',
                    'server':str(bigip_int2_pip)})

    output['modules'] = modules
        
    commands = []
    commands.append({'check':'tmsh list /ltm profile fastl4 loose_fastL4',
                     'command':'tmsh create /ltm profile fastl4 loose_fastL4 defaults-from fastL4 loose-close enabled loose-initialization enabled idle-timeout 300 reset-on-timeout disabled',
                     'server':str(bigip_int1_pip)})
    commands.append({'check':'tmsh list /security log profile local-afm-log',
                     'command':'tmsh create /security log profile local-afm-log { network replace-all-with { local-afm-log { publisher local-db-publisher filter { log-acl-match-accept enabled log-acl-match-drop enabled log-acl-match-reject enabled } } } }',
                     'server':str(bigip_int1_pip)})
    commands.append({'check':'tmsh list /security firewall policy log_all_afm',
                     'command':'tmsh create /security firewall policy log_all_afm rules add { allow_all  { action accept log yes place-before first } deny_all { action reject log yes place-after allow_all  }}',
                     'server':str(bigip_int1_pip)})

    commands.append({'check':'tmsh list /ltm virtual-address 0.0.0.0',
                     'command':'create /ltm virtual-address 0.0.0.0 traffic-group none',
                     'server':str(bigip_int1_pip)})

    commands.append({'check':'tmsh list /ltm virtual-address %s' %(str(parameters['f5_Int_Untrusted_IP'])),
                     'command':'create /ltm virtual-address %s traffic-group none' %(str(parameters['f5_Int_Untrusted_IP'])),
                     'server':str(bigip_int1_pip)})

    output['commands'] = commands

    localcommands = []
    try:
        network_client.load_balancers.get('%s_F5_External' %(resource_group),'f5-ext-alb')
    except:
        localcommands.append({'check':'az network lb show -g %s_F5_External --name f5-ext-alb' %(resource_group),
                     'command':"az network lb create --resource-group %s_F5_External --public-ip-address f5-alb-ext-pip0 --frontend-ip-name loadBalancerFrontEnd0 --backend-pool-name LoadBalancerBackEnd --name f5-ext-alb" %(resource_group)
                     })
        pass
    localcommands.append({'check':None,
                          'command': "az network lb frontend-ip create --name loadBalancerFrontEnd1 --lb-name f5-ext-alb -g %s_F5_External  --public-ip-address f5-alb-ext-pip1" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb probe create  --lb-name f5-ext-alb  -g %s_F5_External  --name is_alive --port 80 --protocol Http --path /" %(resource_group)})

    localcommands.append({'check':None,
                          'command':"az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext0 --lb-name f5-ext-alb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])})
    localcommands.append({'check':None,
                          'command':"az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext1 --lb-name f5-ext-alb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 22 --frontend-port 22  --lb-name f5-ext-alb  -g %s_F5_External  --name ssh_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 443 --frontend-port 443  --lb-name f5-ext-alb  -g %s_F5_External  --name rdp_gw_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 3389 --frontend-port 3389  --lb-name f5-ext-alb  -g %s_F5_External  --name rdp_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})

    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 80 --frontend-port 80  --lb-name f5-ext-alb  -g %s_F5_External  --name http_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd1 --probe-name is_alive" %(resource_group)})

    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 443 --frontend-port 443  --lb-name f5-ext-alb  -g %s_F5_External  --name ssl_visible_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd1 --probe-name is_alive" %(resource_group)})

    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 8443 --frontend-port 8443  --lb-name f5-ext-alb  -g %s_F5_External  --name ssl_not_visible_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd1 --probe-name is_alive" %(resource_group)})



    try:
        network_client.load_balancers.get('%s_F5_External' %(resource_group),'f5-ext-ilb')
    except:
        localcommands.append({'check':None,
                              'command':"az network lb create --resource-group %s_F5_External --private-ip-address %s --subnet %s --frontend-ip-name loadBalancerFrontEnd0 --backend-pool-name LoadBalancerBackEnd --name f5-ext-ilb" %(resource_group, 
                                                                                                                                                                                                                                        str(parameters['f5_Ext_Untrusted_IP']),subnet.id)})
        pass

    try:
        network_client.load_balancers.get('%s_F5_Internal' %(resource_group),'f5-int-ilb')
    except:
        localcommands.append({'check':None,
                              'command':"az network lb create --resource-group %s_F5_Internal --private-ip-address %s --subnet %s --frontend-ip-name loadBalancerFrontEnd0 --backend-pool-name LoadBalancerBackEnd --name f5-int-ilb" %(resource_group, 
                                                                                                                                                                                                                                        str(parameters['f5_Int_Untrusted_IP']),internalsubnet.id)})
        pass


    localcommands.append({'check':None,
                          'command':"az network lb probe create  --lb-name f5-ext-ilb  -g %s_F5_External  --name is_alive --port 80 --protocol Http --path /" %(resource_group)})

    localcommands.append({'check':None,
                          'command':"az network lb probe create  --lb-name f5-int-ilb  -g %s_F5_Internal  --name is_alive --port 80 --protocol Http --path /" %(resource_group)})

    localcommands.append({'check':None,
                          'command':"az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext0 --lb-name f5-ext-ilb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])})
    localcommands.append({'check':None,
                          'command':"az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext1 --lb-name f5-ext-ilb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])})

    localcommands.append({'check':None,
                          'command':"az network nic ip-config address-pool add --resource-group %s_F5_Internal --nic-name %s-ext0 --lb-name f5-int-ilb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_int['dnsLabel'],f5_int['dnsLabel'])})
    localcommands.append({'check':None,
                          'command':"az network nic ip-config address-pool add --resource-group %s_F5_Internal --nic-name %s-ext1 --lb-name f5-int-ilb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_int['dnsLabel'],f5_int['dnsLabel'])})

    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 22 --frontend-port 22  --lb-name f5-ext-ilb  -g %s_F5_External  --name ssh_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 80 --frontend-port 80  --lb-name f5-int-ilb  -g %s_F5_Internal  --name http_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 443 --frontend-port 443  --lb-name f5-ext-ilb  -g %s_F5_External  --name rdp_gw_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 3389 --frontend-port 3389  --lb-name f5-ext-ilb  -g %s_F5_External  --name rdp_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})
    localcommands.append({'check':None,
                          'command':"az network lb rule create --backend-port 8443 --frontend-port 8443  --lb-name f5-ext-ilb  -g %s_F5_External  --name https_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)})

    output['localcommands'] = localcommands

    

#    print json.dumps(output)
#    sys.exit(0)

if options.debug:
    print "\n\n#### Azure Infrastructure ####\n\n"
    print "az network route-table update --resource-group %s --name %s --set tags.f5_tg=traffic-group-1" %(resource_group,
                                                                                                           parameters['f5_Int_Untrust_RouteTableName'])
    print "az network route-table update --resource-group %s --name %s --set tags.f5_ha=%s" %(resource_group,
                                                                                          parameters['f5_Int_Untrust_RouteTableName'],
                                                                                          f5_ext['routeTableTag'])

    print "az network route-table update --resource-group %s --name %s --set tags.f5_tg=traffic-group-1" %(resource_group,
                                                                                                    parameters['internal_Subnets_RouteTableName'])
    print "az network route-table update --resource-group %s --name %s --set tags.f5_ha=%s" %(resource_group,
                                                                                          parameters['internal_Subnets_RouteTableName'],
                                                                                          f5_int['routeTableTag'])

    print """\n\naz network nsg rule create --nsg-name %(dnsLabel)s-ext-nsg  --resource-group %(external_rg)s --priority 1000 -n allow_http --destination-port-ranges 80 --protocol tcp
az network nsg rule create --nsg-name %(dnsLabel)s-ext-nsg  --resource-group %(external_rg)s --priority 1001 -n allow_https --destination-port-ranges 443 --protocol tcp
az network nsg rule create --nsg-name %(dnsLabel)s-ext-nsg  --resource-group %(external_rg)s --priority 1002 -n allow_rdp --destination-port-ranges 3389 --protocol tcp
az network nsg rule create --nsg-name %(dnsLabel)s-ext-nsg  --resource-group %(external_rg)s --priority 1003 -n allow_ssh --destination-port-ranges 22 --protocol tcp
az network nsg rule create --nsg-name %(dnsLabel)s-ext-nsg  --resource-group %(external_rg)s --priority 1004 -n allow_moressh --destination-port-ranges 2200-2299 --protocol tcp""" %({'external_rg':f5_ext_resource_group,
                                                                                                                                                                                       'dnsLabel':f5_ext['dnsLabel']})

    parameters['resource_group'] = resource_group
    print "az network lb create --resource-group %s_F5_External --public-ip-address f5-alb-ext-pip0 --frontend-ip-name loadBalancerFrontEnd0 --backend-pool-name LoadBalancerBackEnd --name f5-ext-alb" %(resource_group)
    print "az network lb probe create  --lb-name f5-ext-alb  -g %s_F5_External  --name is_alive --port 80 --protocol Http --path /" %(resource_group)
#    print "az network lb address-pool create -g %s --lb-name f5-ext-alb --name LoadBalancerBackEnd" %(resource_group)
    print "az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext0 --lb-name f5-ext-alb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])
    print "az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext1 --lb-name f5-ext-alb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])
    print "az network lb rule create --backend-port 22 --frontend-port 22  --lb-name f5-ext-alb  -g %s_F5_External  --name ssh_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)


    print "az network lb create --resource-group %s_F5_External --private-ip-address %s --subnet %s --frontend-ip-name loadBalancerFrontEnd0 --backend-pool-name LoadBalancerBackEnd --name f5-ext-ilb" %(resource_group, 
                                                                                                                                                                                                                        str(parameters['f5_Ext_Untrusted_IP']),subnet.id)
    print "az network lb probe create  --lb-name f5-ext-ilb  -g %s_F5_External  --name is_alive --port 80 --protocol Http --path /" %(resource_group)
    print "az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext0 --lb-name f5-ext-ilb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])
    print "az network nic ip-config address-pool add --resource-group %s_F5_External --nic-name %s-ext1 --lb-name f5-ext-ilb --address-pool LoadBalancerBackEnd --ip-config-name %s-self-ipconfig" %(resource_group, f5_ext['dnsLabel'],f5_ext['dnsLabel'])
    print "az network lb rule create --backend-port 22 --frontend-port 22  --lb-name f5-ext-ilb  -g %s_F5_External  --name ssh_vs --protocol Tcp --backend-pool-name LoadBalancerBackEnd --floating-ip true --frontend-ip-name loadBalancerFrontEnd0 --probe-name is_alive" %(resource_group)


    print "\n\n### Route Table Assocations ###"
    print "#external bigip to internal"
    print "\n\naz network vnet subnet update --name %(f5_Ext_Trusted_SubnetName)s --vnet-name %(vnetName)s --resource-group %(resource_group)s  --route-table %(f5_Ext_Trust_RouteTableName)s" %(parameters)
    print "az network vnet subnet update --name %(ipS_Trusted_SubnetName)s --vnet-name %(vnetName)s --resource-group %(resource_group)s  --route-table %(ipS_Trust_RouteTableName)s" %(parameters)
    print "# from internal bigip to external"
    print "az network vnet subnet update --name %(f5_Int_Untrusted_SubnetName)s --vnet-name %(vnetName)s --resource-group %(resource_group)s  --route-table %(f5_Int_Untrust_RouteTableName)s" %(parameters)
    print "az network vnet subnet update --name %(ipS_Untrusted_SubnetName)s --vnet-name %(vnetName)s --resource-group %(resource_group)s  --route-table %(ipS_Untrust_RouteTableName)s" %(parameters)
    print "az network vnet subnet update --name %(vdmS_SubnetName)s --vnet-name %(vnetName)s --resource-group %(resource_group)s  --route-table %(internal_Subnets_RouteTableName)s" %(parameters)
    print "az network vnet subnet update --name %(management_SubnetName)s --vnet-name %(vnetName)s --resource-group %(resource_group)s  --route-table %(internal_Subnets_RouteTableName)s" %(parameters)
    
    print "\n\n     External VIP: %s %s" %(external_pip[0],external_pip[1])
    print "External BIG-IP 1: %s %s" %(bigip_ext_ext1_pip,bigip_ext_ext1_ip)
    print "External BIG-IP 2: %s %s\n" %(bigip_ext_ext2_pip,bigip_ext_ext2_ip)
    print "Internal BIG-IP 1: %s %s" %(bigip_ext_int1_pip,bigip_ext_int1_ip)
    print "Internal BIG-IP 2: %s %s" %(bigip_ext_int2_pip,bigip_ext_int2_ip)

if options.action == "external_setup":
    output['route_tables'] = [
#        {'resource_group':resource_group,
#         'name':parameters['f5_Int_Untrust_RouteTableName'],
#         'f5_ha':f5_ext['routeTableTag'],
#         'f5_tg':'traffic-group-1'},
                              {'resource_group':resource_group,
                               'name':parameters['ipS_Untrust_RouteTableName'],
                               'f5_ha':f5_ext['routeTableTag'],
                               'f5_tg':'traffic-group-1'}
                           ]
    output['servers'] = [{'server':str(bigip_ext1_pip)},{'server':str(bigip_ext2_pip)}]
    print json.dumps(output)

if options.action == "internal_setup":
    output['route_tables'] = [{'resource_group':resource_group,
                               'name':parameters['internal_Subnets_RouteTableName'],
                               'f5_ha':f5_int['routeTableTag'],
                               'f5_tg':'traffic-group-1'},
#                              {'resource_group':resource_group,
#                               'name':parameters['f5_Ext_Trust_RouteTableName'],
#                               'f5_ha':f5_int['routeTableTag'],
#                               'f5_tg':'traffic-group-1',
#                               'f5_self':'self_2nic'},
                              {'resource_group':resource_group,
                               'name':parameters['ipS_Trust_RouteTableName'],
                               'f5_ha':f5_int['routeTableTag'],
                               'f5_tg':'traffic-group-1',
                               'f5_self':'self_2nic'}]
    output['servers'] = [{'server':str(bigip_int1_pip)},{'server':str(bigip_int2_pip)}]
    print json.dumps(output)


# u'f5_Ext_Trusted_SubnetPrefix': IPNetwork('192.168.1.0/24'),
# u'f5_Ext_Untrusted_SubnetPrefix': IPNetwork('192.168.0.0/24'),
# u'f5_Int_Trusted_SubnetPrefix': IPNetwork('192.168.3.0/24'),
# u'f5_Int_Untrusted_SubnetPrefix': IPNetwork('192.168.2.0/24'),
# u'gatewaySubnetPrefix': IPNetwork('192.168.255.224/27'),
# u'management_SubnetPrefix': IPNetwork('172.16.0.0/24'),
# u'vdmS_SubnetPrefix': IPNetwork('172.16.1.0/24'),

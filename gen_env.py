import requests
import json
import sys
import os
session = requests.Session()
headers = {'user-agent':'f5-gen-env/0.1','Metadata':'true'}
METADATA_URL="http://169.254.169.254/metadata/instance?api-version=2017-08-01"

output = {}

try:
    request = session.get(METADATA_URL,headers=headers)
    data = json.loads(request.text)
    output['resource_group'] = data['compute']['resourceGroupName']
    output['location'] = data['compute']['location']
    output['subscription_id'] = data['compute']['subscriptionId']
except requests.exceptions.ConnectionError:
    #print "Please run on Azure Linux JumpBox"
    #sys.exit(1)
    output['resource_group'] = os.environ.get('AZURE_RESOURCE_GROUP','')
    output['subscription_id'] = os.environ.get('AZURE_SUBSCRIPTION_ID','')
    output['location'] = os.environ.get('location','')

    pass

try:
    sp = json.load(open('sp.json'))
    output['client_id'] = sp["appId"]
    output['client_secret'] = sp["password"]
    output["tenant_id"] = sp["tenant"]
except:
    output['client_id'] = ''
    output['client_secret'] = ''
    output["tenant_id"] = ''
    pass


TEMPLATE="""export AZURE_SUBSCRIPTION_ID="%(subscription_id)s"
export AZURE_CLIENT_ID="%(client_id)s"
export AZURE_SECRET="%(client_secret)s"
export AZURE_TENANT="%(tenant_id)s"
export AZURE_CLOUD_ENVIRONMENT="AzureUSGovernment"
export AZURE_RESOURCE_GROUP="%(resource_group)s"
export location="%(location)s"
export f5_username=""
export f5_password=""
export f5_unique_short_name=""
export f5_unique_short_name2=""

export f5_license_key_1=""
export f5_license_key_2=""
export f5_license_key_3=""
export f5_license_key_4=""


export F5_VALIDATE_CERTS=no

az cloud set -n AzureUSGovernment

which az
az login \
--service-principal \
-u "$AZURE_CLIENT_ID" \
-p "$AZURE_SECRET" \
--tenant "$AZURE_TENANT"
"""
print TEMPLATE %(output)

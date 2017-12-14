#!/usr/bin/env python
import requests
import json
import sys
import os
import re

is_regkey = re.compile("([A-Z]{5}-[A-Z]{5}-[A-Z]{5}-[A-Z]{5}-[A-Z]{7})",re.M)

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
try:
    key_text = open('keys.txt').read()
    keys =  is_regkey.findall(key_text)
    output['key1'] = ''
    output['key2'] = ''
    output['key3'] = ''
    output['key4'] = ''
    for x in range(len(keys)):
        output['key%s' %(x+1)] = keys[x]
except:
    output['key1'] = ''
    output['key2'] = ''
    output['key3'] = ''
    output['key4'] = ''
    pass

output['f5_username'] = os.environ.get('USER','')

TEMPLATE="""export AZURE_SUBSCRIPTION_ID="%(subscription_id)s"
export AZURE_CLIENT_ID="%(client_id)s"
export AZURE_SECRET="%(client_secret)s"
export AZURE_TENANT="%(tenant_id)s"
export AZURE_CLOUD_ENVIRONMENT="AzureUSGovernment"
export AZURE_RESOURCE_GROUP="%(resource_group)s"
export location="%(location)s"

export f5_unique_short_name="%(resource_group)sext"
export f5_unique_short_name2="%(resource_group)sint"

export f5_license_key_1="%(key1)s"
export f5_license_key_2="%(key2)s"
export f5_license_key_3="%(key3)s"
export f5_license_key_4="%(key4)s"

export f5_username="%(f5_username)s"
export f5_password=""

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

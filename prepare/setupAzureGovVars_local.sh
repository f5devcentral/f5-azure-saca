#!/usr/bin/env bash

#Need to check OS / Platform
osName=`uname -s`
case $osName in
  Linux*)   export machine="Linux" ;;
  Darwin*)  export machine="Mac" ;;
  *)        export machine="UNKNOWN:$osName" ;;
esac

echo $machine

if [[ "$machine" == "Mac" ]]; then
  echo "OSX Detected, need to Install / Update Brew and jq..."
  #Need to update brew and make sure jq is installed to process json
  echo "updating & upgrading brew..."
  brew update || brew update
  brew upgrade

  if brew ls --versions jq > /dev/null; then
    # The package is installed
    echo "jq installed proceeding..."
  else
    echo "installing jq..."
    brew install jq
  fi
elif [[ "$machine" == "Linux" ]]; then
  if [ -f /etc/redhat-release ]; then
    yum -y update
    yum -y install jq
  fi
  if [ -f /etc/lsb-release ]; then
    apt-get --assume-yes update
    apt-get --assume-yes install jq
  fi
fi

#Map Subscription
export ARM_SUBSCRIPTION_ID=`az account show | jq -r '.id'`

#Create ServicePrincipal for ClientID and Secret
spn=`az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$ARM_SUBSCRIPTION_ID" --name http://sccaServicePrincipalName`

echo "Setting environment variables for Terraform"
export ARM_CLIENT_ID=`echo $spn | jq -r '.appId'`
echo $spn | jq -r '.appId'
export ARM_CLIENT_SECRET=`echo $spn | jq -r '.password'`
echo $spn | jq -r '.password'
export ARM_TENANT_ID=`az account show | jq -r '.tenantId'`
az account show | jq -r '.tenantId'

# Not needed for public, required for usgovernment, german, china
#export ARM_ENVIRONMENT=`az account show | jq -r '.environmentName'`
export ARM_ENVIRONMENT="usgovernment"

# Accept terms for programatic deployment of images
az vm image terms accept --offer f5-big-ip-byol --publisher f5-networks --plan f5-big-ip-byol
az vm image terms accept --offer f5-big-ip-best --publisher f5-networks --plan f5-big-ip-best

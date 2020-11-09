#!/bin/bash

# Change these variables according to your needs
    RESOURCE_GROUP_NAME=tfstate
    STORAGE_ACCOUNT_NAME=tfstate$RANDOM
    CONTAINER_NAME=tfstate
    VAULT_NAME=sccaKeyVault$RANDOM
    SECRET_NAME=sccaSecret

#Map Subscription
export ARM_SUBSCRIPTION_ID=`az account show | jq -r '.id'`

#Create ServicePrincipal for ClientID and Secret
    spn=`az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$ARM_SUBSCRIPTION_ID" --name http://sccaServicePrincipalName`

# Create resource group
    az group create --name $RESOURCE_GROUP_NAME --location usgovvirginia

# Create storage account
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
    ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

# Create Azure KeyVault
    az keyvault create -g $RESOURCE_GROUP_NAME --name $VAULT_NAME

# Set Azure KeyVault Secret value to storage account key
    az keyvault secret set --vault-name $VAULT_NAME --name $SECRET_NAME --value $ACCOUNT_KEY

echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
export ARM_CLIENT_ID=`echo $spn | jq -r '.appId'`
export ARM_CLIENT_SECRET=`echo $spn | jq -r '.password'`
export ARM_TENANT_ID=`az account show | jq -r '.tenantId'`
export ARM_ACCESS_KEY=$(az keyvault secret show --name $SECRET_NAME --vault-name $VAULT_NAME --query value -o tsv)

# Not needed for public, required for usgovernment, german, china
#export ARM_ENVIRONMENT=`az account show | jq -r '.environmentName'`
export ARM_ENVIRONMENT="usgovernment"

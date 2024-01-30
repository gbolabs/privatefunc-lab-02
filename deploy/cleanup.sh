#!/bin/bash

# Description: Initialize the Azure environment
subscription="199fc2c4-a57c-4049-afbe-e1831f4b2f6e"
resourcegroup="rg-private-function-gbo-02"

# based on parameter "$1"
if [ "$1" = "rg" ]; then
    # delete the resource group
    # set the subscription
    az account set --subscription $subscription
    az group delete --name $resourcegroup --yes
elif [ "$1" = "deploy" ]; then
    # delete the deployment
    # set the subscription
    az account set --subscription $subscription
    az deployment group list --resource-group $resourcegroup --query "[].name" --output tsv | xargs -L1 bash -c 'az deployment group delete --name "$0" --resource-group "$1" --yes' --
else
    echo "Usage: $0 [rg|deploy]"
    echo "rg: delete the resource group"
    echo "deploy: delete the deployment"
    exit 1
fi

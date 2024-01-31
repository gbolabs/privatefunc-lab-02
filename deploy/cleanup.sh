#!/bin/bash

# Description: Initialize the Azure environment
subscription="199fc2c4-a57c-4049-afbe-e1831f4b2f6e"
resourcegroup="rg-private-function-gbo-02"

# based on parameter "$1"
if [ "$1" = "rg" ]; then
    # delete the resource group
    # set the subscription
    az account set --subscription $subscription
    az group delete --name "$resourcegroup" --yes
elif [ "$1" = "deploy" ]; then
    # delete the deployment
    # set the subscription
    az account set --subscription $subscription

    echo "Delete the deployments of the resource group $resourcegroup"

    deployments=$(az deployment group list -g $resourcegroup --query "[?properties.provisioningState != 'Running'].[name]" -o tsv)

    for deployment in $deployments; do
        echo "Deleting deployment $deployment"
        az deployment group delete -n $deployment -g "$resourcegroup" --no-wait
    done
else
    echo "Usage: $0 [rg|deploy]"
    echo "rg: delete the resource group"
    echo "deploy: delete the deployment"
    exit 1
fi

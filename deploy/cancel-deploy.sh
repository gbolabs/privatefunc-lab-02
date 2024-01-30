#!/bin/bash

resourceGroup="rg-private-function-gbo-02"

deployments=$(az deployment group list --resource-group $resourceGroup --query "[].name" -o tsv)

for deployment in $deployments; do
    az deployment group cancel --name $deployment --resource-group $resourceGroup
done

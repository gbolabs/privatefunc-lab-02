# Description: Initialize the Azure environment
subscripton="199fc2c4-a57c-4049-afbe-e1831f4b2f6e"
resourcegroup="rg-private-function-gbo-02"

# set the subscription
az account set --subscription $subscripton

# clear the resource-group
az group delete --name $resourcegroup --yes --no-wait
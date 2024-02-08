# Integrate variables from env/variables.sh file
. ./env/variables.sh

# Set the subscription
az account set --subscription $subscription

# Generate the deployment unique string
uniqueString=$(openssl rand -hex 3)
deploymentName="deploy-infra-$uniqueString"

kvPrivateDnsZoneId=$(az network private-dns zone show --name "privatelink.vaultcore.azure.net" --resource-group $resourcegroup --query "id" --output tsv)
storageBlobPrivateDnsZoneId=$(az network private-dns zone show --name "privatelink.blob.core.windows.net" --resource-group $resourcegroup --query "id" --output tsv)
storageFilePrivateDnsZoneId=$(az network private-dns zone show --name "privatelink.file.core.windows.net" --resource-group $resourcegroup --query "id" --output tsv)

# validate the bicep file
echo "Validate the bicep file"
az deployment group validate --resource-group $resourcegroup --template-file iac/infrastructure.bicep \
    --parameters location=$location \
    environment='dev' \
    serviceConnectionPrincipal='' \
    applicationName='prvfct' \
    uniqueString=$unique \
    devEntraIdGroupIdForKvAccessPolicies=$resourceAdminId

# deploy infarstructure
az deployment group create --resource-group $resourcegroup --template-file iac/infrastructure.bicep \ 
    --name $deploymentName \
    --parameters location=$location \
    environment='dev' \
    serviceConnectionPrincipal='' \
    applicationName='prvfct' \
    uniqueString=$unique \
    devEntraIdGroupIdForKvAccessPolicies=$resourceAdminId

# retrieve the output of the deployment
echo "Retrieve the output of the deployment"

json=$(az deployment group show --name $deploymentName --resource-group $resourcegroup --query "properties.outputs" | jq 'to_entries | map({name: .key, value: .value.value})')

echo $json | jq
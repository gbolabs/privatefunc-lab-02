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

# deploy infarstructure
az deployment group create --resource-group $resourcegroup --template-file iac/infrastructure.bicep --name $deploymentName \
    --parameters location=$location \
    environment='dev' \
    serviceConnectionPrincipal='' \
    applicationName='prvfct' \
    uniqueString=$unique \
    keyVaultSku='standard' \
    storageAccountSkuName='Standard_LRS' \
    vnetName=$vnet \
    endpointSubnetName=$subnetpep \
    kvPrivateDnsZoneId=$kvPrivateDnsZoneId \
    devEntraIdGroupIdForKvAccessPolicies=$resourceAdminId \
    storageBlobPrivateDnsZoneId=$storageBlobPrivateDnsZoneId \
    storageFilePrivateDnsZoneId=$storageFilePrivateDnsZoneId

# retrieve the output of the deployment
echo "Retrieve the output of the deployment"
az deployment group show --resource-group $resourcegroup --name $deploymentName --query properties.outputs --output table
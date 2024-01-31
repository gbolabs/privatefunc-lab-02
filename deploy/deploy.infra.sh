# Integrate variables from .vars file
. ./.vars

# Set the subscription
az account set --subscription $subscription

# Generate the deployment unique string
uniqueString=$(openssl rand -hex 3)
deploymentName="deploy-infra-$uniqueString"

# deploy infarstructure
az deployment group create --resource-group $resourcegroup --template-file iac/infrastructure.bicep --name $deploymentName \
    --parameters location=$location \
    environment='dev' \
    serviceConnectionPrincipal='' \
    applicationName='prvfct' \
    uniqueString='gbo' \
    keyVaultSku='standard' \
    storageAccountSkuName='Standard_LRS' \
    vnetName=$vnet \
    endpointSubnetName=$subnetpep \
    kvPrivateDnsZoneId='/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net' \
    devEntraIdGroupIdForKvAccessPolicies='' \
    storageBlobPrivateDnsZoneId='/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net' \
    storageFilePrivateDnsZoneId='/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'

# retrieve the output of the deployment
echo "Retrieve the output of the deployment"
az deployment group show --resource-group $resourcegroup --name $deploymentName --query properties.outputs --output table
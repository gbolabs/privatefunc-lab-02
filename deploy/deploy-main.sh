# Description: Initialize the Azure environment
subscripton="199fc2c4-a57c-4049-afbe-e1831f4b2f6e"
resourcegroup="rg-private-function-gbo-02"
vnet="vnet-private-function-gbo-02"
vnetVm="vnet-private-function-vm-gbo-02"
subnetpep="subnet-pep-private-function-gbo-02"
subnetapp="subnet-app-private-function-gbo-02"
subnetvm="subnet-vm-private-function-gbo-02"
location="uksouth"
vmname="vm-private-function-gbo-02"

# set the subscription
echo "Set the subscription"
az account set --subscription $subscripton

# deploy infarstructure
az deployment group create --resource-group $resourcegroup --template-file iac/infrastructure.bicep --name deploy-infra \
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


appPlanId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.Web/serverFarms/iwb-prvfct-asp-dev-gbo"
uaId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.ManagedIdentity/userAssignedIdentities/iwb-prvfct-id-kvsecretsaccess-dev-gbo"	
appInsightConnectionString="InstrumentationKey=28998cad-9855-4257-aaed-e8c63065c39a;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/"
keyVaultUri="https://iwb-prvfct-kv-dev-gbo.vault.azure.net/"
keyVaultName="iwb-prvfct-kv-dev-gbo"
storageAccountName="iwbprvfctsadevgbo"
appFuncPrivateDnsZoneId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"

# deploy function app
az deployment group create --resource-group $resourcegroup --template-file iac/functionapp.bicep --name deploy-functionapp \
    --parameters location=$location \
    environment='dev' \
    applicationName='prvfct' \
    functionName='f1' \
    uniqueString='gbo' \
    functionUserAssignedManagedIdentity="$uaId" \
    runtimeName='dotnet-isolated' \
    runtimeVersion='8.0' \
    vnetName=$vnet \
    endpointSubnetName=$subnetpep \
    appSubnetName=$subnetapp \
    appServicePlanId="$appServicePlanId" \
    applicationInsightsConnectionString="$appInsightConnectionString" \
    keyVaultUri="$keyVaultUri" \
    keyVaultName="$keyVaultName" \
    appFuncPrivateDnsZoneId="$appFuncPrivateDnsZoneId" \
    storageAccountName="$storageAccountName"
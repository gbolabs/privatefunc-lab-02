# Integrate variables from .vars file
. ./.vars

# Set the subscription
az account set --subscription $subscription

# Generate the deployment unique string
uniqueString=$(openssl rand -hex 3)
deploymentName="deploy-funcapp-$uniqueString"

appServicePlanId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.Web/serverFarms/iwb-prvfct-asp-dev-gbo"
uaId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-02/providers/Microsoft.ManagedIdentity/userAssignedIdentities/iwb-prvfct-id-kvsecretsaccess-dev-gbo"	
appInsightConnectionString="InstrumentationKey=28998cad-9855-4257-aaed-e8c63065c39a;IngestionEndpoint=https://uksouth-1.in.applicationinsights.azure.com/;LiveEndpoint=https://uksouth.livediagnostics.monitor.azure.com/"
keyVaultUri="https://iwb-prvfct-kv-dev-gbo.vault.azure.net/"
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
    runtimeVersion='6.0' \
    vnetName=$vnet \
    endpointSubnetName=$subnetpep \
    appSubnetName=$subnetapp \
    appServicePlanId="$appServicePlanId" \
    applicationInsightsConnectionString="$appInsightConnectionString" \
    keyVaultUri="$keyVaultUri" \
    keyVaultName="$keyVaultName" \
    appFuncPrivateDnsZoneId="$appFuncPrivateDnsZoneId" \
    storageAccountName="$storageAccountName"
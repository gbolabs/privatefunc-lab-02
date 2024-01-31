# Integrate variables from .vars file
. ./.vars

# Set the subscription
az account set --subscription $subscription

# Generate the deployment unique string
uniqueString=$(openssl rand -hex 3)
deploymentName="deploy-funcapp-$uniqueString"

set the right values here below
exit 1

appServicePlanId=""
uaId=""
appInsightConnectionString=""
keyVaultUri=""
storageAccountName=""
appFuncPrivateDnsZoneId=""

# deploy function app
az deployment group create --resource-group $resourcegroup --template-file iac/functionapp.bicep --name deploy-functionapp \
    --parameters location=$location \
    environment='dev' \
    applicationName='prvfct' \
    functionName='f1' \
    uniqueString=$unique \
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
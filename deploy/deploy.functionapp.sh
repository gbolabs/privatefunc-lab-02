# Integrate variables from env/variables.sh file
. ./env/variables.sh

# Set the subscription
az account set --subscription $subscription

# Generate the deployment unique string
uniqueString=$(openssl rand -hex 3)
deploymentName="deploy-funcapp-$uniqueString"

appServicePlanId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-98a/providers/Microsoft.Web/serverfarms/gbl-prvfct-asp-dev-98a"
uaId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-98a/providers/Microsoft.ManagedIdentity/userAssignedIdentities/gbl-prvfct-id-kvsecretsaccess-dev-98a"
applicationInsightsResourceId="/subscriptions/199fc2c4-a57c-4049-afbe-e1831f4b2f6e/resourceGroups/rg-private-function-gbo-98a/providers/Microsoft.Insights/components/gbl-prvfct-appi-dev-98a"
keyVaultUri="https://gbl-prvfct-kv-dev-98a.vault.azure.net/"
storageAccountName="gblprvfctsadev98a"
appFuncPrivateDnsZoneId=$(az network private-dns zone show --name "privatelink.azurewebsites.net" --resource-group $resourcegroup --query "id" --output tsv)

uniqueString=$(openssl rand -hex 3)
deploymentName="deploy-infra-$uniqueString"

# Enable internet access to the storage account
az storage account update --name $storageAccountName --resource-group $resourcegroup --default-action Allow --public-network-access Enabled

# validate the bicep file
az deployment group validate --resource-group $resourcegroup --template-file iac/functionapp.bicep \
    --parameters location=$location \
    environment='dev' \
    uniqueString=$unique \
    applicationName='prvfct' \
    functionName='f1' \
    runtimeName='dotnet-isolated' \
    runtimeVersion='6.0'

# deploy function app
az deployment group create --resource-group $resourcegroup --template-file iac/functionapp.bicep \
    --name $deploymentName \
    --parameters location=$location \
    environment='dev' \
    uniqueString=$unique \
    applicationName='prvfct' \
    functionName='f1' \
    runtimeName='dotnet-isolated' \
    runtimeVersion='6.0'

# Disable internet access to the storage account
az storage account update --name $storageAccountName --resource-group $resourcegroup --default-action Deny --public-network-access Disabled
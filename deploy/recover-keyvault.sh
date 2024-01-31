. ./env/variables.sh

# set the subscription
echo "Set the subscription"
az account set --subscription $subscription

# recover the keyvault
echo "Recover the keyvault $keyVaultName"
az keyvault recover --name $keyVaultName
# $1 is the subscription id
# $2 is the ketvault name to recover

# set the subscription
echo "Set the subscription"
az account set --subscription $1

# recover the keyvault
echo "Recover the keyvault $2"
az keyvault recover --name $2
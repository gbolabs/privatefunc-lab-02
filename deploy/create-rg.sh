. ./env/variables.sh

# set the subscription
echo "Set the subscription"
az account set --subscription $subscription

# create the resource-group

echo "Create the resource-group"
az group create --name $resourcegroup --location $location --tags "DeployedBy=Gautier Boder, DeployedFrom=Azure CLI" --managed-by $resourceAdminId

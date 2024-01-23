# Description: Initialize the Azure environment
subscripton="199fc2c4-a57c-4049-afbe-e1831f4b2f6e"
resourcegroup="rg-private-function-gbo-02"
vnet="vnet-private-function-gbo-02"
subnetpep="subnet-pep-private-function-gbo-02"
subnetapp="subnet-app-private-function-gbo-02"
subnetvm="subnet-vm-private-function-gbo-02"
location="uksouth"

# set the subscription
az account set --subscription $subscripton

# clear the resource-group
az group delete --name $resourcegroup --yes

# create the resource-group
az group create --name $resourcegroup --location $location --tags "DeployedBy=Gautier Boder, DeployedFrom=Azure CLI"

# Create the VNET
az network vnet create --resource-group $resourcegroup --name $vnet --address-prefixes '192.168.50.0/24'

# Create the subnet for the PEP
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetpep --address-prefixes '192.168.50.0/27' --no-wait

# Create the subnet for the APP
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetapp --address-prefixes '192.168.50.32/27' --no-wait

# Create the subnet for the VM
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetvm --address-prefixes '192.168.50.64/27'

# Create a ubuntu VM
az vm create --resource-group $resourcegroup --name vm-ubuntu --image Ubuntu2204 --admin-username azureuser --generate-ssh-keys --subnet $subnetvm

# Authorize the port 22
az vm open-port --resource-group $resourcegroup --name vm-ubuntu --port 22

# Private Azure DNS Zone for the VNET for the PEP azurewebsites.net (Azure Web App) storageaccount (Azure Storage, blob and file) and keyvault (Azure Key Vault) and return id
websiteDnsZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.azurewebsites.net --output tsv --query id)
blobStorageZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.blob.core.windows.net --output tsv --query id)
fileStorageZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.file.core.windows.net --output tsv --query id)
keyVaultZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.vaultcore.azure.net --output tsv --query id)

# Create the link between the VNET and the DNS Zone
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.azurewebsites.net --name link-vnet-azurewebsites --virtual-network $vnet --registration-enabled false
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.blob.core.windows.net --name link-vnet-blob --virtual-network $vnet --registration-enabled false
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.file.core.windows.net --name link-vnet-file --virtual-network $vnet --registration-enabled false
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.vaultcore.azure.net --name link-vnet-vault --virtual-network $vnet --registration-enabled false


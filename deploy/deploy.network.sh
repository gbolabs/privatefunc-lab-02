. ./.vars

# set the subscription
echo "Set the subscription"
az account set --subscription $subscription

# Create the VNET
echo "Create the VNET $vnet"
az network vnet create --resource-group $resourcegroup --name $vnet --address-prefixes $vnetAddress

# Create the subnet for the PEP
echo "Create the subnet $subnetpep"
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetpep --address-prefixes $pepAddress

# Create the subnet for the APP
echo "Create the subnet $subnetapp"
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetapp --address-prefixes $appAddress --delegations 'Microsoft.Web/serverFarms'

# Create the VNet for the VM
echo "Create the VNET $vnetVm"
az network vnet create --resource-group $resourcegroup --name $vnetVm --address-prefixes $vnetVmAddress

# Create the subnet for the VM
echo "Create the subnet $subnetvm"
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnetVm --name $subnetvm --address-prefixes $vmAddress
# Peer the VNETs
echo "Peer the VNETs"
az network vnet peering create --resource-group $resourcegroup --name $vnet-to-$vnetVm --vnet-name $vnet --remote-vnet $vnetVm --allow-vnet-access
az network vnet peering create --resource-group $resourcegroup --name $vnetVm-to-$vnet --vnet-name $vnetVm --remote-vnet $vnet --allow-vnet-access

# Private Azure DNS Zone for the VNET for the PEP azurewebsites.net (Azure Web App) storageaccount (Azure Storage, blob and file) and keyvault (Azure Key Vault) and return id
echo "Create the private DNS Zones"
websiteDnsZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.azurewebsites.net --output tsv --query id)
blobStorageZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.blob.core.windows.net --output tsv --query id)
fileStorageZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.file.core.windows.net --output tsv --query id)
keyVaultZoneId=$(az network private-dns zone create --resource-group $resourcegroup --name privatelink.vaultcore.azure.net --output tsv --query id)

# Create the link between the VNET and the DNS Zone
echo "Create the link between the VNET and the DNS Zone"
echo "Link VNET $vnetVm to privatelink.azurewebsites.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.azurewebsites.net \
    --name link-$vnetVm-azurewebsites --virtual-network $vnetVm --registration-enabled false
echo "Link VNET $vnetVm to privatelink.blob.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.blob.core.windows.net \
    --name link-$vnetVm-blob --virtual-network $vnetVm --registration-enabled false
echo "Link VNET $vnetVm to privatelink.file.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.file.core.windows.net \
    --name link-$vnetVm-file --virtual-network $vnetVm --registration-enabled false
echo "Link VNET $vnetVm to privatelink.vaultcore.azure.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.vaultcore.azure.net \
    --name link-$vnetVm-vault --virtual-network $vnetVm --registration-enabled false

echo "Link VNET $vnet to privatelink.azurewebsites.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.azurewebsites.net \
    --name link-$vnet-azurewebsites --virtual-network $vnet --registration-enabled false
echo "Link VNET $vnet to privatelink.blob.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.blob.core.windows.net \
    --name link-$vnet-blob --virtual-network $vnet --registration-enabled false
echo "Link VNET $vnet to privatelink.file.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.file.core.windows.net \
    --name link-$vnet-file --virtual-network $vnet --registration-enabled false
echo "Link VNET $vnet to privatelink.vaultcore.azure.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.vaultcore.azure.net \
    --name link-$vnet-vault --virtual-network $vnet --registration-enabled false
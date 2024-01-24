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

# create the resource-group

echo "Create the resource-group"
az group create --name $resourcegroup --location $location --tags "DeployedBy=Gautier Boder, DeployedFrom=Azure CLI"

# Create the VNET
echo "Create the VNET $vnet"
az network vnet create --resource-group $resourcegroup --name $vnet --address-prefixes '192.168.50.0/24'

# Create the subnet for the PEP
echo "Create the subnet $subnetpep"
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetpep --address-prefixes '192.168.50.0/27'

# Create the subnet for the APP
echo "Create the subnet $subnetapp"
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnet --name $subnetapp --address-prefixes '192.168.50.32/27'

# Create the VNet for the VM
echo "Create the VNET $vnetVm"
az network vnet create --resource-group $resourcegroup --name $vnetVm --address-prefixes '192.168.60.0/24'

# Create the subnet for the VM
echo "Create the subnet $subnetvm"
az network vnet subnet create --resource-group $resourcegroup --vnet-name $vnetVm --name $subnetvm --address-prefixes '192.168.60.128/27'

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
    --name link-vnet-azurewebsites --virtual-network $vnetVm --registration-enabled false
echo "Link VNET $vnetVm to privatelink.blob.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.blob.core.windows.net \
    --name link-vnet-blob --virtual-network $vnetVm --registration-enabled false
echo "Link VNET $vnetVm to privatelink.file.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.file.core.windows.net \
    --name link-vnet-file --virtual-network $vnetVm --registration-enabled false
echo "Link VNET $vnetVm to privatelink.vaultcore.azure.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.vaultcore.azure.net \
    --name link-vnet-vault --virtual-network $vnetVm --registration-enabled false

echo "Link VNET $vnet to privatelink.azurewebsites.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.azurewebsites.net \
    --name link-vnet-azurewebsites --virtual-network $vnet --registration-enabled false
echo "Link VNET $vnet to privatelink.blob.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.blob.core.windows.net \
    --name link-vnet-blob --virtual-network $vnet --registration-enabled false
echo "Link VNET $vnet to privatelink.file.core.windows.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.file.core.windows.net \
    --name link-vnet-file --virtual-network $vnet --registration-enabled false
echo "Link VNET $vnet to privatelink.vaultcore.azure.net"
az network private-dns link vnet create --resource-group $resourcegroup --zone-name privatelink.vaultcore.azure.net \
    --name link-vnet-vault --virtual-network $vnet --registration-enabled false

# Create a ubuntu VM
echo "Create a ubuntu VM"
vm=$(az vm create --resource-group $resourcegroup --name $vmname --image Ubuntu2204 \
    --admin-username azureuser --generate-ssh-keys --subnet $subnetvm --vnet-name $vnetVm \
    --public-ip-sku Standard --size Standard_B1s \
    --nsg-rule SSH --assign-identity "[system]" \
    --ssh-key-values /host-home/.ssh/id_rsa.pub \
    --output tsv --query name)

hostname=$(az vm show --resource-group $resourcegroup --name $vmname --show-details --query publicIps -o tsv)

echo "Install the Azure CLI on the VM"
az vm run-command invoke --resource-group $resourcegroup --name $vmname --command-id RunShellScript \
    --scripts "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"

echo "VM: $vm / $hostname"
. ./.vars

# set the subscription
echo "Set the subscription"
az account set --subscription $subscription

# Create a ubuntu VM
echo "Create a ubuntu VM"
vm=$(az vm create --resource-group $resourcegroup --name $vmname --image Ubuntu2204 \
    --admin-username azureuser --generate-ssh-keys --subnet $subnetvm --vnet-name $vnetVm \
    --public-ip-sku Standard --size Standard_B1s \
    --nsg-rule SSH --assign-identity "[system]" \
    --public-ip-address-dns-name $vmname \
    --output tsv --query name)

hostname=$(az vm show --resource-group $resourcegroup --name $vmname --show-details --query publicIps -o tsv)

echo "VM: $vm / $hostname"
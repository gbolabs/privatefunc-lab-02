# Description: Initialize the Azure environment
subscription="199fc2c4-a57c-4049-afbe-e1831f4b2f6e"
unique="98a"
resourcegroup="rg-privatefunction-gbl-$unique"
location="switzerlandnorth"
vmname="vm-private-function-gbo-client-$unique"
resourceAdminId="74fa1dc1-96ae-4b65-9905-9004b475ff9d"

# copy of the generated name value used when recovering the key vault
keyVaultName="gbl-prvfct-kv-dev-$unique"

vnet="gbl-prvfct-vnet-dev-$unique"
vnetAddress="192.168.50.0/24"
subnetpep="gbl-prvfct-snet-dev-001"
pepAddress="192.168.50.0/27"
subnetapp="gbl-prvfct-snet-dev-002"
appAddress="192.168.50.32/27"

vnetVm="gbl-devvm-vnet-dev-$unique"
vnetVmAddress="192.168.60.0/24"
subnetvm="subnet-vm"
vmAddress="192.168.60.0/27"
param vnetName string
param subnetName string
param dnsId string
param pEdnpointName string
param pLinkServiceId string
param pLinkGroupId string
param location string = resourceGroup().location

// Vnet - Subnet
resource vnetRes 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}
resource subnetRes 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnetRes
  name: subnetName
}

// Endpoint
resource pEdnpt 'Microsoft.Network/privateEndpoints@2023-05-01'={
  name: pEdnpointName
  location: location
  properties:{
    subnet:{
      id: subnetRes.id
    }
    privateLinkServiceConnections:[
      {
        name: 'default'
        properties:{
          privateLinkServiceId: pLinkServiceId
          groupIds:[
            pLinkGroupId
          ]
        }
      }
    ]
  }
}

// DNS Zone group
resource kvPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = {
  name: format('pdnszg-{0}', pEdnpointName)
  parent: pEdnpt
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: dnsId
        }
      }
    ]
  }
}

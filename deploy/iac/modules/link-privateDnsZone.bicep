param vnetId string
param privateDnsZoneName string
param autoRegistration bool = false
param location string = 'global'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource dnsZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: uniqueString(resourceGroup().id, privateDnsZoneName, vnetId)
  location: location
  properties: {
    registrationEnabled: autoRegistration
    virtualNetwork: {
      id: vnetId
    }
  }
}

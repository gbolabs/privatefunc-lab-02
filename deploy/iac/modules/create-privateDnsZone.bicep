param location string = 'global'
param zoneName string

resource pDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: location
}

output zoneId string = pDnsZone.id
output zoneName string = pDnsZone.name

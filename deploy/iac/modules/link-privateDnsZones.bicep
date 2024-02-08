param vnetId string
@description('{"name":"","autoRegistration":false}')
param privateDnsZoneConfigs array
param location string = 'global'

@batchSize(1) // Avoid trying to update the resource in parallel
module linkPrivateDnsModule 'link-privateDnsZone.bicep' = [for config in privateDnsZoneConfigs: {
  name: format('linkPrivateDnsZone-{0}-{1}', config.name, uniqueString(vnetId))
  params: {
    location: location
    vnetId: vnetId
    privateDnsZoneName: config.name
    autoRegistration: config.autoRegistration
  } 
}]

param name string
param location string = resourceGroup().location

param kind string = ''
param reserved bool = false
param sku object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  sku: sku
  kind: kind
  properties: {
    reserved: reserved
  }
}

// Outputs
output appServicePlanId string = appServicePlan.id

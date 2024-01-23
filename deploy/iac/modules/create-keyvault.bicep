param kvName string
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'
param location string = resourceGroup().location
param privateOnly bool
param accessPolicies array = []

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    accessPolicies: accessPolicies
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enablePurgeProtection: true
    softDeleteRetentionInDays: 7
    enableSoftDelete: true
    publicNetworkAccess: privateOnly ? 'Disabled' : 'Enabled'
  }
}

output kvId string = kv.id
output kvUri string = kv.properties.vaultUri
output kvName string = kv.name

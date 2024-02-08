param name string
param location string = resourceGroup().location

param skuName string = 'Standard_LRS'
param kind string = 'StorageV2'
param accessTier string = 'Hot'
param publicNetworkAccess bool = false

param containers array = []

// Resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    defaultToOAuthAuthentication: true
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    routingPreference: {
      routingChoice: publicNetworkAccess ? 'InternetRouting' : 'MicrosoftRouting'
      publishMicrosoftEndpoints: publicNetworkAccess ? false : true
      publishInternetEndpoints: publicNetworkAccess ? false : true
    }
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    resource container 'containers' = [for container in containers: {
      name: container.name
      properties: {
        publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
      }
    }]
  }
}

// Output
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name

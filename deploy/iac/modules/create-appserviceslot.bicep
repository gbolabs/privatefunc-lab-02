// mandatory parameters
param location string = resourceGroup().location
param functionSlotName string
param parentSiteName string
param kind string
param linuxFxVersion string

// optional parameters
param appSettings object = {}
param managedIdentity bool = true
param userAssignedIdentity string = ''
param appInsightsConnectionString string = ''
param keyVaultUri string = ''

resource functionSlot 'Microsoft.Web/sites/slots@2023-01-01' = {
  parent: parentSite
  name: functionSlotName
  kind: kind
  location: location
  properties: {
    serverFarmId: parentSite.properties.serverFarmId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
  identity: {
    type: !empty(userAssignedIdentity) ? 'SystemAssigned, UserAssigned' : managedIdentity ? 'SystemAssigned' : 'None'
    userAssignedIdentities: !empty(userAssignedIdentity) ? {
      '${userAssignedIdentity}': {}
    } : {

    }
  }
  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: union(appSettings,
      !empty(appInsightsConnectionString) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString } : {},
      !empty(keyVaultUri) ? { AZURE_KEY_VAULT_ENDPOINT: keyVaultUri } : {})
  }
}

// =================================================================================================================
// Existing resources
// =================================================================================================================
resource parentSite 'Microsoft.Web/sites@2023-01-01' existing = {
  name: parentSiteName
}

// ==========================================================================
// Outputs
// ==========================================================================
output functionSlotId string = functionSlot.id

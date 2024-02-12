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
param isPublic bool = false
param subnetId string = ''
param runtimeVersion string = ''
param alwaysOn bool = true
param appCommandLine string = ''
param numberOfWorkers int = -1
param minimumElasticInstanceCount int = -1
param use32BitWorkerProcess bool = false
param functionAppScaleLimit int = -1
param allowedOrigins array = []


resource functionSlot 'Microsoft.Web/sites/slots@2023-01-01' = {
  parent: parentSite
  name: functionSlotName
  kind: kind
  location: location
  properties: {
    virtualNetworkSubnetId: subnetId
    serverFarmId: parentSite.properties.serverFarmId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: contains(kind, 'linux') ? linuxFxVersion : ''
      netFrameworkVersion: contains(kind, 'linux') ? '' : format('v{0}', replace(runtimeVersion, '.0', ''))
      alwaysOn: alwaysOn
      ftpsState: 'Disabled'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      minimumElasticInstanceCount: minimumElasticInstanceCount != -1 ? minimumElasticInstanceCount : null
      use32BitWorkerProcess: use32BitWorkerProcess
      functionAppScaleLimit: functionAppScaleLimit != -1 ? functionAppScaleLimit : null
      cors: {
        allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
  }
  identity: {
    type: !empty(userAssignedIdentity) ? 'SystemAssigned, UserAssigned' : managedIdentity ? 'SystemAssigned' : 'None'
    userAssignedIdentities: !empty(userAssignedIdentity) ? {
      '${userAssignedIdentity}': {}
    } : {}
  }

  resource networkConfig 'networkConfig@2023-01-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: subnetId
      swiftSupported: true
    }
  }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: union(appSettings,
      !empty(appInsightsConnectionString) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString } : {},
      !empty(keyVaultUri) ? { AZURE_KEY_VAULT_ENDPOINT: keyVaultUri } : {})
  }

  resource configLogs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: { fileSystem: { level: 'Verbose' } }
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
    }
    dependsOn: [
      configAppSettings
    ]
  }

  resource accessRestrictions 'config@2023-01-01' = {
    name: 'web'
    properties: {
      publicNetworkAccess: isPublic ? 'Enabled' : 'Disabled'
      scmIpSecurityRestrictions: isPublic ? [] : [
        // Default to deny all
        {
          action: 'Deny'
          priority: 2147483647
          tag: 'Default'
          ipAddress: 'Any'
          subnetMask: 'Any'
        }
      ]
      scmIpSecurityRestrictionsUseMain: false
      ipSecurityRestrictions: isPublic ? [] : [
        // Default to deny all
        {
          action: 'Deny'
          priority: 2147483647
          tag: 'Default'
          ipAddress: 'Any'
          subnetMask: 'Any'
        }
      ]
    }
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
output functionSlotPrincipalId string = functionSlot.identity.principalId

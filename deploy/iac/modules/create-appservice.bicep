param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param appInsightsConnectionString string = ''
param keyVaultUri string
param appServicePlanId string
param managedIdentity bool = true
param userAssignedIdentity string

// Runtime Properties
@allowed([
  'dotnet', 'dotnetcore', 'dotnet-isolated', 'node', 'python', 'java', 'powershell', 'custom'
])
param runtimeName string
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
param runtimeVersion string

// Microsoft.Web/sites Properties
param kind string

// Microsoft.Web/sites/config
param allowedOrigins array = []
param alwaysOn bool = true
param appCommandLine string = ''
param appSettings object = {}
param clientAffinityEnabled bool = false
param enableOryxBuild bool = contains(kind, 'linux')
param functionAppScaleLimit int = -1
param linuxFxVersion string = runtimeNameAndVersion
param minimumElasticInstanceCount int = -1
param numberOfWorkers int = -1
param scmDoBuildDuringDeployment bool = false
param use32BitWorkerProcess bool = false
param isPublic bool = false
param subnetId string = ''

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    publicNetworkAccess: isPublic ? 'Enabled' : 'Disabled'
    virtualNetworkSubnetId: subnetId
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: contains(kind, 'linux') ? linuxFxVersion : ''
      netFrameworkVersion: contains(kind, 'linux') ? '' : format('v{0}', runtimeVersion)
      alwaysOn: alwaysOn
      ftpsState: 'Disabled'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers != -1 ? numberOfWorkers : null
      minimumElasticInstanceCount: minimumElasticInstanceCount != -1 ? minimumElasticInstanceCount : null
      use32BitWorkerProcess: use32BitWorkerProcess
      functionAppScaleLimit: functionAppScaleLimit != -1 ? functionAppScaleLimit : null
      functionsRuntimeScaleMonitoringEnabled: false
      cors: {
        allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
      }
    }
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
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
      {
        SCM_DO_BUILD_DURING_DEPLOYMENT: string(scmDoBuildDuringDeployment)
        ENABLE_ORYX_BUILD: string(enableOryxBuild)
      },
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

  resource networkConfig 'networkConfig@2023-01-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: subnetId
      swiftSupported: true
    }
  }
}

output identityPrincipalId string = managedIdentity ? appService.identity.principalId : ''
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output id string = appService.id

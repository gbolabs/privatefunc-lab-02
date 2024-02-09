param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param appInsightsConnectionString string = ''
param appServicePlanId string
param keyVaultUri string = ''
param managedIdentity bool = !empty(keyVaultUri)
param userAssignedIdentity string

// Runtime Properties
@allowed([
  'dotnet', 'dotnetcore', 'dotnet-isolated', 'node', 'python', 'java', 'powershell', 'custom'
])
param runtimeName string
param runtimeNameAndVersion string = '${runtimeName}|${runtimeVersion}'
param runtimeVersion string

// Function Settings
@allowed([
  '~4', '~3', '~2', '~1'
])
param extensionVersion string = '~4'

// Microsoft.Web/sites Properties
param kind string = 'functionapp,linux'

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
param isPublic bool = true
param subnetId string
param storageAccountName string
param functionName string

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
module functions 'create-appservice.bicep' = {
  name: '${name}-functions'
  params: {
    name: name
    location: location
    tags: tags
    allowedOrigins: allowedOrigins
    isPublic: isPublic
    subnetId: subnetId
    alwaysOn: alwaysOn
    appCommandLine: appCommandLine
    appInsightsConnectionString: appInsightsConnectionString
    appServicePlanId: appServicePlanId
    appSettings: union(appSettings, {
        AzureWebJobsStorage: storageConnectionString
        FUNCTIONS_EXTENSION_VERSION: extensionVersion
        FUNCTIONS_WORKER_RUNTIME: runtimeName
        WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
        WEBSITE_CONTENTSHARE: contentFileShareModule.outputs.fileShareName
        WEBSITE_VNET_ROUTE_ALL: isPublic ? '' : '1'
        WEBSITE_CONTENTOVERVNET: isPublic ? '' : '1'
        WEBSITE_OVERRIDE_STICKY_DIAGNOSTICS_SETTINGS: 0
      })
    clientAffinityEnabled: clientAffinityEnabled
    enableOryxBuild: enableOryxBuild
    functionAppScaleLimit: functionAppScaleLimit
    keyVaultUri: keyVaultUri
    kind: kind
    linuxFxVersion: linuxFxVersion
    managedIdentity: managedIdentity
    userAssignedIdentity: userAssignedIdentity
    minimumElasticInstanceCount: minimumElasticInstanceCount
    numberOfWorkers: numberOfWorkers
    runtimeName: runtimeName
    runtimeVersion: runtimeVersion
    runtimeNameAndVersion: runtimeNameAndVersion
    scmDoBuildDuringDeployment: scmDoBuildDuringDeployment
    use32BitWorkerProcess: use32BitWorkerProcess
  }
}
// Function content file share
var fileShareName = 'function-${functionName}-content'
module contentFileShareModule 'create-fileShare.bicep' = {
  name: '${name}-functions-content'
  params: {
    fileShareName: fileShareName
    storageAccountName: storageAccountName
  }
}

// Existing resource
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Outputs
output id string = functions.outputs.id
output identityPrincipalId string = managedIdentity ? functions.outputs.identityPrincipalId : ''
output name string = functions.outputs.name
output uri string = functions.outputs.uri

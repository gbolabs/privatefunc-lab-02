// This template deploys the infrastructure resources required to operate the Handle Middleware Functions.
// ========================================================

// Parameters
param location string = 'westeurope'
@allowed([
  'sandbox'
  'dev'
  'qa'
  'prod'
])
param environment string
@description('Use to build the resource name according to the naming convention')
param applicationName string
param functionName string
param uniqueString string
param appSettings object = {}
@description('Use to store the secrets in the keyvault and then reference them in the appSettings. Structure is { "secretName": "{}", "secretValue": "{}" }')
param functionUserAssignedManagedIdentity string = ''
param runtimeName string = ''
param runtimeVersion string = ''

// Prerequisites infrastructure parameters
param vnetName string
param endpointSubnetName string
param appSubnetName string

param appServicePlanId string
param applicationInsightsConnectionString string
param keyVaultUri string
param keyVaultName string
@description('Used to register keyvault private endpoint avoiding to create multiple private dns zone for all the keyvaults')
param appFuncPrivateDnsZoneId string

param storageAccountName string

// Integrates naming convention
var namingConvention = loadJsonContent('common/naming-rules.bicep.json')
var defaults = loadJsonContent('common/defaults.bicep.json')

// Explicitly define the scope to be at resource group level
targetScope = 'resourceGroup'

// Resources
var functionAppName = format(namingConvention.namingPatterns.function, applicationName, functionName, environment, uniqueString)
var pepFctAppName = format(namingConvention.namingPatterns.privateEndpoint, format('{0}-func-{1}', applicationName, functionName), environment, uniqueString)
module function 'modules/create-functions.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'function', environment, uniqueString)
  params: {
    appSettings: appSettings
    isPublic: false
    location: location
    appServicePlanId: appServicePlanId
    appInsightsConnectionString: applicationInsightsConnectionString
    alwaysOn: false
    keyVaultUri: keyVaultUri
    name: functionAppName
    subnetId: appSubnet.id
    runtimeName: runtimeName != '' ? runtimeName : defaults.function.runtimeName
    runtimeVersion: runtimeVersion != '' ? runtimeVersion : defaults.function.runtimeVersion
    storageAccountName: storage.name
    functionName: functionName
    userAssignedIdentity: functionUserAssignedManagedIdentity
    kind: 'functionapp'
  }
}
module makeFuncAppPrivate 'modules/make-private.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'makeFuncAppPrivate', environment, uniqueString)
  params: {
    location: location
    dnsId: appFuncPrivateDnsZoneId
    pEdnpointName: pepFctAppName
    pLinkGroupId: 'sites'
    pLinkServiceId: function.outputs.id
    subnetName: endpointSubnetName
    vnetName: vnetName
  }
}

// Permissions to keyvault
module keyVaultAccessPolicyForFuncApp 'modules/add-keyVaultAccessPolicy.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'keyVaultAccessPolicyForFuncApp', environment, uniqueString)
  params: {
    kvName: keyVaultName
    objectId: function.outputs.identityPrincipalId
    secretsPolicies: [
      'get'
      'list'
    ]
  }
}

// Permissions to storage account
// Disabled as we don't have the right access on the storage account, requires to be either owner, Role Based Access Control Administrator
// module storageAccountAccessPolicy 'modules/add-storageAccountAccessPolicy.bicep' = {
//   name: format('{0}-storage-access-policy', functionAppName)
//   params: {
//     storageAccountName: storageAccountName
//     objectId: functionA.outputs.identityPrincipalId
//     roleDefinitionId: defaults.rbacRoleIds.storageBlobDataContributor
//   }
// }

// Existing resources
resource vnetRes 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: appSubnetName
  parent: vnetRes
}
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Outputs
output functionAppName string = functionAppName
output functionAppId string = function.outputs.id
output functionAppUri string = function.outputs.uri

//
// This template deploys the infrastructure resources required to operate the Handle Middleware Functions.
//
//
// =====================================================================================================================

// *********************************************************************************************************************
// Parameters
// *********************************************************************************************************************
param location string = 'westeurope'
@allowed([
  'sandbox'
  'dev'
  'qa'
  'prod'
])
param environment string
param uniqueString string
@description('Use to build the resource name according to the naming convention,')
param applicationName string // eg. mwbh
@description('Name of handler (e.g. datahubhandler)')
param functionName string
@description('Use to build the name of User Assigned Managed Identity for KeyVault Secrets Access.')
param kvAccessUaIdNameComponent string = ''
param runtimeName string = ''
param runtimeVersion string = ''

// *********************************************************************************************************************
// Variables
// *********************************************************************************************************************
// Integrates naming convention
var namingConvention = loadJsonContent('common/naming-rules.bicep.json')
var defaults = loadJsonContent('common/defaults.bicep.json')
var mwbhCommon = loadJsonContent('common/mwbh-common.bicep.json')

// Networking
// eg. gbl-mwbh-vnet-dev-g4m
var vnetName = format(namingConvention.namingPatterns.virtualNetwork, applicationName, environment, uniqueString)
// eg. gbl-mwbh-snet-dev-002
var appSubnetName = format(namingConvention.namingPatterns.subnet, applicationName, environment, mwbhCommon.networking.subnet.app.index, uniqueString)
var endpointSubnetName = format(namingConvention.namingPatterns.subnet, applicationName, environment, mwbhCommon.networking.subnet.endpoint.index, uniqueString)

// Private DNS Zone
var appFuncPrivateDnsZoneId = format('/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/privateDnsZones/{2}', mwbhCommon.networking.privateDns.subscriptionId,  mwbhCommon.networking.privateDns.resourceGroup, defaults.privateDnsZoneNames.azurewebsites)
// Keyvault
var keyVaultName = format(namingConvention.namingPatterns.keyVault, applicationName, environment, uniqueString)
// AppServicePlan eg. gbl-mwbh-asp-dev-g4m
var serverFarmName = format(namingConvention.namingPatterns.appServicePlan, applicationName, environment, uniqueString)
// Application Insights
var appInsightsName = format(namingConvention.namingPatterns.applicationInsights, applicationName, environment, uniqueString)
// Storage Account
var storageAccountName = format(namingConvention.namingPatterns.storageAccount, applicationName, environment, uniqueString)
// Keyvault Secrets Access User Assigned Managed Identity
var uaIdNameComponent = length(kvAccessUaIdNameComponent) > 0 ? kvAccessUaIdNameComponent : 'kvsecretsaccess'
var uaIdFullName = format(namingConvention.namingPatterns.managedIdentity, applicationName, uaIdNameComponent, environment, uniqueString)

// *********************************************************************************************************************
// Resources
// *********************************************************************************************************************
var functionAppName = format(namingConvention.namingPatterns.function, applicationName, functionName, environment, uniqueString)
var pepFctAppName = format(namingConvention.namingPatterns.privateEndpoint, format('{0}-func-{1}', applicationName, functionName), environment, uniqueString)
module function 'modules/create-functions.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'function', environment, uniqueString)
  params: {
    isPublic: false
    location: location
    appServicePlanId: appServicePlan.id
    appInsightsConnectionString: appInsightsRes.properties.ConnectionString
    alwaysOn: false
    keyVaultUri: keyVault.properties.vaultUri
    name: functionAppName
    subnetId: appSubnet.id
    runtimeName: runtimeName != '' ? runtimeName : defaults.function.runtimeName
    runtimeVersion: runtimeVersion != '' ? runtimeVersion : defaults.function.runtimeVersion
    storageAccountName: storage.name
    functionName: functionName
    userAssignedIdentity: userAssignedId.id
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

// *********************************************************************************************************************
// Existing resources
// *********************************************************************************************************************
resource vnetRes 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: appSubnetName
  parent: vnetRes
}
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource appInsightsRes 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' existing = {
  name: serverFarmName
}
resource userAssignedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: uaIdFullName
}

// *********************************************************************************************************************
// Outputs
// *********************************************************************************************************************
output functionAppName string = functionAppName
output functionAppId string = function.outputs.id
output functionAppUri string = function.outputs.uri

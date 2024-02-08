// This template deploys the infrastructure resources required to operate the Handle Middleware Functions.
// 
//
// ==========================================================================================================================

// ***************************************************************************************************************************
// Parameters
// ***************************************************************************************************************************
param location string = 'westeurope'
@allowed([
  'sandbox'
  'dev'
  'qa'
  'prod'
])
param environment string
param serviceConnectionPrincipal string = ''
param applicationName string
param uniqueString string

@description('Object Id of the MS Entra ID Group used to grant management of the keyvault secrets')
param devEntraIdGroupIdForKvAccessPolicies string = ''

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
// eg. gbl-mwbh-snet-dev-001
var endpointSubnetName = format(namingConvention.namingPatterns.subnet, applicationName, environment, mwbhCommon.networking.subnet.endpoint.index, uniqueString)

// *********************************************************************************************************************
// Resources
// *********************************************************************************************************************
var managedIdentityName = format(namingConvention.namingPatterns.managedIdentity, applicationName,'kvsecretsaccess', environment, uniqueString)
module managedIdentityModule 'modules/create-userAssignedManagedId.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'managedIdentity-kvsecrets', environment, uniqueString)
  params: {
    location: location
    managedIdName: managedIdentityName
  }
}

var keyVaultName = format(namingConvention.namingPatterns.keyVault, applicationName, environment, uniqueString)
var pepKvName = format(namingConvention.namingPatterns.privateEndpoint, format('{0}-keyvault', applicationName), environment, uniqueString)
module keyVaultModule 'modules/create-keyvault.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'keyvault', environment, uniqueString)
  params: {
    location: location
    kvName: keyVaultName
    privateOnly: true
    skuName: defaults.skus.keyVaultSku
  }
}

module keyVaultAccessPolicyForPipeline 'modules/add-keyVaultAccessPolicy.bicep' = if(serviceConnectionPrincipal != '') {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'keyVaultAccessPolicyForPipeline', environment, uniqueString)
  params: {
    kvName: keyVaultModule.outputs.kvName
    objectId: serviceConnectionPrincipal
    secretsPolicies: [
      'set'
    ]
  }
}

module keyVaultAccessPolicyForUAMgdId 'modules/add-keyVaultAccessPolicy.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'keyVaultAccessPolicyForUAMgdId', environment, uniqueString)
  params: {
    kvName: keyVaultModule.outputs.kvName
    objectId: managedIdentityModule.outputs.managedIdentityPrincipalId
    secretsPolicies: [
      'get'
      'list'
    ]
  }
}

module keyVaultAccessPolicyForDevEntraIDGroup 'modules/add-keyVaultAccessPolicy.bicep' = if (length(devEntraIdGroupIdForKvAccessPolicies) > 0) {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'keyVaultAccessPolicyForDevEntraIDGroup', environment, uniqueString)
  params: {
    kvName: keyVaultModule.outputs.kvName
    objectId: devEntraIdGroupIdForKvAccessPolicies
    secretsPolicies: [
      'get'
      'list'
      'set'
    ]
  }
}

module makeKeyVaultPrivateModule 'modules/make-private.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'makeKeyVaultPrivate', environment, uniqueString)
  params: {
    location: location
    dnsId: kvPdns.id
    pEdnpointName: pepKvName
    pLinkGroupId: 'vault'
    pLinkServiceId: keyVaultModule.outputs.kvId
    subnetName: endpointSubnetName
    vnetName: vnetName
  }
}

var logAnalyticsWorkspaceName = format(namingConvention.namingPatterns.logAnalyticsWorkspace, applicationName, environment, uniqueString)
var appInsightsName = format(namingConvention.namingPatterns.applicationInsights, applicationName, environment, uniqueString)
module lawAppiModule 'modules/create-lawappi.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'lawAppiModule', environment, uniqueString)
  params: {
    location: location
    appInsightsName: appInsightsName
    keyVaultName: keyVaultModule.outputs.kvName
    logAnalyticsName: logAnalyticsWorkspaceName
    appInsightInstrumentationKeySecretName: ''
    appInsightsConnectionStringSecretName: ''
  }
}

var appServicePlanName = format(namingConvention.namingPatterns.appServicePlan, applicationName, environment, uniqueString)
module appServicePlanModule 'modules/create-appserviceplan.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'appServicePlan', environment, uniqueString)
  params: {
    location: location
    name: appServicePlanName
    sku: environment == 'prod' ? defaults.skus.appServicePlan.prod : defaults.skus.appServicePlan.devqa
    kind: '' // let empty for Elastic Premium
    reserved: false
  }
}

var storageAccountName = format(namingConvention.namingPatterns.storageAccount, applicationName, environment, uniqueString)
module storageAccountPlanModule 'modules/create-storageaccount.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'storageAccount', environment, uniqueString)
  params: {
    location: location
    name: storageAccountName
    skuName: environment == 'prod' ? defaults.skus.storageAccount.prod.name : defaults.skus.storageAccount.devqa.name
    kind: 'StorageV2'
    accessTier: 'Hot'
  }
}

// Blob private endpoint
var stoPendptName = format(namingConvention.namingPatterns.privateEndpoint, format('{0}-sa-blob', applicationName), environment, uniqueString)
module makeStorageAccountPrivate 'modules/make-private.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'pep-sa-blob', environment, uniqueString)
  params: {
    location: location
    dnsId: blobPdns.id
    pEdnpointName: stoPendptName
    pLinkGroupId: 'blob'
    pLinkServiceId: storageAccountPlanModule.outputs.storageAccountId
    subnetName: endpointSubnetName
    vnetName: vnetName
  }
}

// File private endpoint
var stoFilePendptName = format(namingConvention.namingPatterns.privateEndpoint, format('{0}-sa-file', applicationName), environment, uniqueString)
module makeStorageAccountFilePrivate 'modules/make-private.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'pep-sa-file', environment, uniqueString)
  params: {
    location: location
    dnsId: filePdns.id
    pEdnpointName: stoFilePendptName
    pLinkGroupId: 'file'
    pLinkServiceId: storageAccountPlanModule.outputs.storageAccountId
    subnetName: endpointSubnetName
    vnetName: vnetName
  }
}

// *********************************************************************************************************************
// Existing resources
// *********************************************************************************************************************
resource blobPdns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: defaults.privateDnsZoneNames.blob
  scope: resourceGroup(mwbhCommon.networking.privateDns.subscriptionId,mwbhCommon.networking.privateDns.resourceGroup)
}
resource filePdns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: defaults.privateDnsZoneNames.file
  scope: resourceGroup(mwbhCommon.networking.privateDns.subscriptionId,mwbhCommon.networking.privateDns.resourceGroup)
}
resource kvPdns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: defaults.privateDnsZoneNames.vault
  scope: resourceGroup(mwbhCommon.networking.privateDns.subscriptionId,mwbhCommon.networking.privateDns.resourceGroup)
}

// *********************************************************************************************************************
// Outputs
// *********************************************************************************************************************
output applicationInsightsResourceId string = lawAppiModule.outputs.appInsightsId
output storageAccountId string = storageAccountPlanModule.outputs.storageAccountId
output storageAccountName string = storageAccountPlanModule.outputs.storageAccountName
output appServicePlanId string = appServicePlanModule.outputs.appServicePlanId
output keyVaultId string = keyVaultModule.outputs.kvId
output keyVaultUri string = keyVaultModule.outputs.kvUri
output keyVaultName string = keyVaultModule.outputs.kvName
output userAssignedManagedIdentityId string = managedIdentityModule.outputs.managedIdentityId

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
param serviceConnectionPrincipal string = ''
@description('Use to build the resource name according to the naming convention')
param applicationName string
param uniqueString string
param appServiceSku object
param keyVaultSku string
param storageAccountSkuName string

// Prerequisites infrastructure parameters
param vnetName string
param endpointSubnetName string
@description('Used to register keyvault private endpoint avoiding to create multiple private dns zone for all the keyvaults')
param kvPrivateDnsZoneId string

@secure()
@description('Object Id of the MS Entra ID Group used to grant management of the keyvault secrets')
param devEntraIdGroupIdForKvAccessPolicies string = ''

@description('Used to register storage account private endpoint avoiding to create multiple private dns zone for all the storage accounts')
param storageBlobPrivateDnsZoneId string
@description('Used to register storage account private endpoint avoiding to create multiple private dns zone for all the storage accounts')
param storageFilePrivateDnsZoneId string

// Driving output parameters
param appInsightsConnectionStringSecretName string = 'AppInsightsConnectionString'
param appInsightsInstrumentationKeySecretName string = 'AppInsightsInstrumentationKey'

// Integrates naming convention
var namingConvention = loadJsonContent('common/naming-rules.bicep.json')
var defaults = loadJsonContent('common/defaults.bicep.json')

// Explicitly define the scope to be at resource group level
targetScope = 'resourceGroup'

// Resources
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
    skuName: keyVaultSku == '' ? defaults.skus.keyVaultSku : keyVaultSku
  }
}

module keyVaultAccessPolicyForPipeline 'modules/add-keyVaultAccessPolicy.bicep' = {
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

module keyVaultAccessPolicyForDevEntraIDGroup 'modules/add-keyVaultAccessPolicy.bicep' = {
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
    dnsId: kvPrivateDnsZoneId
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
    appInsightInstrumentationKeySecretName: appInsightsInstrumentationKeySecretName
    appInsightsConnectionStringSecretName: appInsightsConnectionStringSecretName
  }
}

var appServicePlanName = format(namingConvention.namingPatterns.appServicePlan, applicationName, environment, uniqueString)
module appServicePlanModule 'modules/create-appserviceplan.bicep' = {
  name: format(namingConvention.namingPatterns.modules, applicationName, 'appServicePlan', environment, uniqueString)
  params: {
    location: location
    name: appServicePlanName
    sku: appServiceSku == {} ? defaults.skus.appServicePlan : appServiceSku
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
    skuName: storageAccountSkuName
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
    dnsId: storageBlobPrivateDnsZoneId
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
    dnsId: storageFilePrivateDnsZoneId
    pEdnpointName: stoFilePendptName
    pLinkGroupId: 'file'
    pLinkServiceId: storageAccountPlanModule.outputs.storageAccountId
    subnetName: endpointSubnetName
    vnetName: vnetName
  }
}

// Outputs
output applicationInsightsResourceId string = lawAppiModule.outputs.appInsightsId
output storageAccountId string = storageAccountPlanModule.outputs.storageAccountId
output storageAccountName string = storageAccountPlanModule.outputs.storageAccountName
output appServicePlanId string = appServicePlanModule.outputs.appServicePlanId
output keyVaultId string = keyVaultModule.outputs.kvId
output keyVaultUri string = keyVaultModule.outputs.kvUri
output keyVaultName string = keyVaultModule.outputs.kvName
output userAssignedManagedIdentityId string = managedIdentityModule.outputs.managedIdentityId

param location string = resourceGroup().location
param appInsightsName string
param logAnalyticsName string
param keyVaultName string = ''
param appInsightsConnectionStringSecretName string = ''
param appInsightInstrumentationKeySecretName string = ''

// ========================================================
// Log Analytics Workspace
// ========================================================
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}
// Application insights on top of the Log Analytics Workspace
resource appInsightsRes 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

module appInsightKey 'create-keyvaultSecret.bicep' = if(!empty(keyVaultName) && !empty(appInsightInstrumentationKeySecretName)) {
  name: 'appInsightKey'
  params: {
    vaultName: keyVaultName
    secretName: appInsightInstrumentationKeySecretName
    secretValue: appInsightsRes.properties.InstrumentationKey
  }
}
module appInsightConnectionString 'create-keyvaultSecret.bicep' = if(!empty(keyVaultName) && !empty(appInsightsConnectionStringSecretName)) {
  name: 'appInsightConnectionString'
  params: {
    vaultName: keyVaultName
    secretName: appInsightsConnectionStringSecretName
    secretValue: appInsightsRes.properties.ConnectionString
  }
}

// ========================================================
// outputs
// ========================================================
output appInsightsConnectionString string = appInsightsRes.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsightsRes.properties.InstrumentationKey
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output appInsightsId string = appInsightsRes.id
output appInsightsName string = appInsightsRes.name

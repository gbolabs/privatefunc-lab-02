param appInsightsName string
param logAnalyticsName string
param location string
param keyVaultName string
param appInsightsConnectionStringSecretName string
param appInsightInstrumentationKeySecretName string

// ========================================================
// Existing resources
resource keyVaultRes 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

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
resource appInsightConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01'= {
  parent: keyVaultRes
  name: appInsightsConnectionStringSecretName
  properties: {
    value: appInsightsRes.properties.ConnectionString
  }
}
resource appInsightInstrumentationKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01'= {
  parent: keyVaultRes
  name: appInsightInstrumentationKeySecretName
  properties: {
    value: appInsightsRes.properties.InstrumentationKey
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

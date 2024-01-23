param storageAccountName string
param objectId string
param roleDefinitionId string

var defaults = loadJsonContent('../common/defaults.bicep.json')

// Existing Storage Account
resource storageAccountRes 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource roleDefinitionIdRes 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: format(defaults.rbacRolePrefixPattern,roleDefinitionId)
}

// Grand Access to Storage Account
resource storageAccountAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccountRes
  name: guid(storageAccountRes.id,objectId,roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionIdRes.id
    principalId: objectId
    principalType: 'ServicePrincipal'
  }
}

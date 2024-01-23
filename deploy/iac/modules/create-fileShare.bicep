param storageAccountName string
param fileShareName string

// FileServices
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: fileShareName
  parent: fileServices
  properties: {
    enabledProtocols:'SMB'
  }
}

// Existing resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Output
output fileShareId string = fileShare.id
output fileShareName string = fileShare.name

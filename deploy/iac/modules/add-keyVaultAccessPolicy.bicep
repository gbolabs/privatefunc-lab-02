param kvName string
param objectId string
param secretsPolicies array = []
param keysPolicies array = []
param certificatesPolicies array = []

// Existing Key Vault
resource keyVaultRes 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: {
          secrets: secretsPolicies
          keys: keysPolicies
          certificates: certificatesPolicies
        }
      }
    ]
  }
}

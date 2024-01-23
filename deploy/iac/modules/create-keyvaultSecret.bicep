// Takes a vault name, secret name, and secret value as input and creates a new secret in the vault using BICEP.
param vaultName string
param secretName string
@secure()
param secretValue string

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: secretName
  parent: kv
  properties: {
    value: secretValue
  }
}

// existing resources
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: vaultName
}

// output
output secretId string = secret.id

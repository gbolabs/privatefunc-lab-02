param location string = resourceGroup().location
param managedIdName string

resource managedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdName
  location: location
}

output managedIdentityId string = managedId.id
output managedIdentityPrincipalId string = managedId.properties.principalId

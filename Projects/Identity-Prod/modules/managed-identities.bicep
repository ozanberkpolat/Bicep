// Creates one user-assigned managed identity (UAMI) per entry. Scope: resource group.
// Naming: <prefix>-<workload>-uami-<env>-<regionCode>
targetScope = 'resourceGroup'

param orgPrefix string
param environmentName string
@description('Short region code, for example gwc.')
param regionCode string
param location string
param tags object

@description('Each entry: { workload: string, description: string }')
param managedIdentities array

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = [
  for mi in managedIdentities: {
    name: '${orgPrefix}-${mi.workload}-uami-${environmentName}-${regionCode}'
    location: location
    tags: union(tags, {
      uamiWorkload: mi.workload
      uamiPurpose: mi.description
    })
  }
]

// One object per identity: { workload, resourceId, principalId, clientId, name }
output identities array = [
  for (mi, i) in managedIdentities: {
    workload: mi.workload
    resourceId: uami[i].id
    principalId: uami[i].properties.principalId
    clientId: uami[i].properties.clientId
    name: uami[i].name
  }
]

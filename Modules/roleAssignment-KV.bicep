
param principalObjectId string
param roleName string
param principalType string = 'User'
param resourceName string

// Load role mappings from JSON
var roleJson = json(loadTextContent('.shared/roles.json'))

// Resolve role definition ID
var roleDefinitionId = roleJson[roleName] ?? roleName

// Reference the existing resource inside the module
resource targetResource 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: resourceName
}

// Role assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(targetResource.id, principalObjectId, roleName)
  scope: targetResource
  properties: {
    principalId: principalObjectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: principalType
  }
}

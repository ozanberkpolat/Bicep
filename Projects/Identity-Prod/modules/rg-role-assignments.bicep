// One role assignment at resource group scope. Called once per assignment by main.bicep.
targetScope = 'resourceGroup'

@description('Object ID of the principal.')
param principalId string

@description('Role definition GUID (not the full resource ID).')
param roleDefinitionId string

@allowed([ 'Group', 'ServicePrincipal', 'User' ])
param principalType string

param assignmentDescription string = ''

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Deterministic GUID per RG + principal + role, so a re-deploy updates instead of failing with RoleAssignmentExists
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
    description: assignmentDescription
  }
}

output roleAssignmentId string = roleAssignment.id

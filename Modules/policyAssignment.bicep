targetScope = 'managementGroup'

param assignmentName string
param policyDefinitionId string
param regionAbbreviation string
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: assignmentName
  location: location
  properties: {
    displayName: assignmentName
    policyDefinitionId: policyDefinitionId
  }
}

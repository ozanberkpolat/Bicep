// This module creates a policy assignment
targetScope = 'managementGroup'

// Parameters for the deployments
param assignmentName string
param policyDefinitionId string
param regionAbbreviation string

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Create policy assignment
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: assignmentName
  location: location
  properties: {
    displayName: assignmentName
    policyDefinitionId: policyDefinitionId
  }
}

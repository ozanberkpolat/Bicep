// This module creates a policy assignment
targetScope = 'managementGroup'

//Importing necessary types
import { regionType, getLocation, regionDefinitionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param assignmentName string
param policyDefinitionId string
param regionAbbreviation regionType

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Create policy assignment
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: assignmentName
  location: location.region
  properties: {
    displayName: assignmentName
    policyDefinitionId: policyDefinitionId
  }
}

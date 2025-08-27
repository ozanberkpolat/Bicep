// This module deploys Managed DevOps Pool

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

var Name = naming.outputs.Resources.managedIdentity

module userAssignedManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  params: {
    name: Name
    location: location.region
  }
}

output ManagedIdentityID string = userAssignedManagedIdentity.outputs.resourceId

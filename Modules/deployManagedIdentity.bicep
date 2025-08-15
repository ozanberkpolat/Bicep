// This module deploys Managed DevOps Pool

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

module userAssignedManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  params: {
    name: naming.outputs.managedIdentityName
    location: location
  }
}

output ManagedIdentityID string = userAssignedManagedIdentity.outputs.resourceId

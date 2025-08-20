// This module deploys Managed DevOps Pool

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

// Deployment Name variable
var deploymentName = 'DeployMI-${projectName}-${regionAbbreviation}'

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
  name: deploymentName
  params: {
    name: naming.outputs.managedIdentity
    location: location.region
  }
}

output ManagedIdentityID string = userAssignedManagedIdentity.outputs.resourceId

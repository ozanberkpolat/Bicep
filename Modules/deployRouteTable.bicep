// This module deploys a Route Table

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

// Deployment Name variable
var deploymentName = 'DeployRT-${projectName}-${regionAbbreviation}'

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

// Default Route for the RT
var defaultRoute = [
  {
    name: 'Traffic_to_LB'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: location.nextHopIp
    }
  }
]

// Deploy Route Table
module Route_Table 'br/public:avm/res/network/route-table:0.4.1' = {
  name: deploymentName
  params: {
    name: naming.outputs.routeTable
    location: location.region
    routes: defaultRoute
  }
}

output routeTableId string = Route_Table.outputs.resourceId

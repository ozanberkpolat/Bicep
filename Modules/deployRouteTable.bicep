// This module deploys a Route Table

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param vNetName string

// Variable for Naming Convention
var routeTableName = 'rt-${vNetName}'

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

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
  name: 'rt-${projectName}'
  params: {
    name: routeTableName
    location: location
    routes: defaultRoute
  }
}

output routeTableId string = Route_Table.outputs.resourceId

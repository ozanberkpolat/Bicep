// This module deploys a subnet into an existing Vnet

//Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param vNetName string
param projectName string
param subnetDescription string
param subnetAddressSpace string
param regionAbbreviation regionType
param subnetDelegation string
param NSG_ID string
param RouteTable_ID string

var deploymentName = 'DeploySubNet-${subnetDescription}-${regionAbbreviation}'

// Variables for naming conventions
var vNetShortName = split(vNetName, '-')[1]
var SubNetFullName = 'sn-${vNetShortName}-${subnetDescription}-${regionAbbreviation}'


// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

module SubNet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  name: deploymentName
  params: {
    name: SubNetFullName
    virtualNetworkName: vNetName
    addressPrefix: subnetAddressSpace
    networkSecurityGroupResourceId: NSG_ID
    routeTableResourceId: RouteTable_ID
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: subnetDelegation
  }
}

output SubNetId string = SubNet.outputs.resourceId
output outboundSubnetName string = SubNetFullName

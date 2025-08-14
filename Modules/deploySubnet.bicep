// This module deploys a subnet into an existing Vnet

//Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param vNetName string
param subnetDescription string
param subnetAddressSpace string
param vNetAddressSpace string
param subscriptionName string
param projectName string
param regionAbbreviation regionType

// Variables for naming conventions
var vNetShortName = split(vNetName, '-')[1]
var SubNetFullName = 'sn-${vNetShortName}-${subnetDescription}-${regionAbbreviation}'

// Deploy NSG for the Subnet
module NSG 'deployNSG.bicep' = {
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subnetAddressSpace: subnetAddressSpace
    subscriptionName: subscriptionName
    vNetAddressSpace: vNetAddressSpace
  }
}

//Deploy Route Table for the subnet
module routeTable 'deployRouteTable.bicep' = {
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    vNetName: vNetName
  }
}

// Deploy subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: '${vNetName}/${SubNetFullName}'
  properties: {
    addressPrefix: subnetAddressSpace
    networkSecurityGroup: {
      id: NSG.outputs.NSGID
    }
    routeTable: {
      id: routeTable.outputs.routeTableId
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output subnetId string = subnet.id
output nsgId string = NSG.outputs.NSGID
output routeTableId string = routeTable.outputs.routeTableId
output outboundSubnetName string = SubNetFullName

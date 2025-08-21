// This module deploys a subnet into an existing Vnet

//Importing necessary types
import { regionType, regionDefinitionType, getLocation  } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param vNetName string
param projectName string
param subnetDescription string
param subnetAddressSpace string
param regionAbbreviation regionType
param subnetDelegation string
param RouteTable_ID string
param vNetAddressSpace string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

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

// Deploy NSG
module NSG 'br/public:avm/res/network/network-security-group:0.5.1' = {
  params: {
    name: naming.outputs.NSGName
    location: location.region
    securityRules: [
      {
    name: 'Allow_All_InsideSubnet'
    properties: {
      priority: 4093
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: subnetAddressSpace
      destinationAddressPrefix: subnetAddressSpace
    }
  }
  {
    name: 'Deny_All_FromOtherSubnetsInVnet'
    properties: {
      priority: 4094
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix:vNetAddressSpace
      destinationAddressPrefix: subnetAddressSpace
    }
  }
  {
    name: 'Allow_All_FromOnPremAndOtherVnets'
    properties: {
      priority: 4095
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '10.0.0.0/8'
      destinationAddressPrefix: subnetAddressSpace
    }
  }
  {
    name: 'Deny_All_Inbound'
    properties: {
      priority: 4096
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
    }
  }
    ]
  }
}


module SubNet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  params: {
    name: SubNetFullName
    virtualNetworkName: vNetName
    addressPrefix: subnetAddressSpace
    networkSecurityGroupResourceId: NSG.outputs.resourceId
    routeTableResourceId: RouteTable_ID
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    delegation: subnetDelegation
  }
}

output Resource_ID string = SubNet.outputs.resourceId
output Name string = SubNetFullName

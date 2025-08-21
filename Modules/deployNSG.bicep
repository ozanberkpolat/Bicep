// This module deploys a Network Security Group with baked-in/default rules

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param subnetAddressSpace string
param vNetAddressSpace string

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

// Deploy NSG
module nsg 'br/public:avm/res/network/network-security-group:0.5.1' = {
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
      sourceAddressPrefixes: [
        vNetAddressSpace
      ]
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

output Resource_ID string = nsg.outputs.resourceId

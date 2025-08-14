// This module deploys a Network Security Group with baked-in/default rules

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param subscriptionName string
param subnetAddressSpace string
param vNetAddressSpace string
param customRules array = []

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Variables for naming conventions
var normalizedSubscriptionName = toLower(replace(replace(subscriptionName, '-', ''), ' ', ''))
var NSGName = 'nsg-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'


// Default inbound rules for the NSG
var defaultRules = [
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
      sourceAddressPrefixes: vNetAddressSpace
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

// Deploy NSG
module nsg 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: NSGName
  params: {
    name: NSGName
    location: location
    securityRules: union(customRules, defaultRules)
  }
}

output NSGID string = nsg.outputs.resourceId

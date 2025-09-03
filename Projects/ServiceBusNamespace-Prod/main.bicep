targetScope = 'subscription'
// Importing necessary types
import { regionType, SKUType } from '../../../modules/.shared/commonTypes.bicep'

param regionAbbreviation regionType
param projectName string
param ServiceBusSKU SKUType
param deploymentRG string = 'rg-mdmdev-profisee-swn'
param vNetRG string = 'rg-vnet-mdmdev-swn'

resource Existing_VNET 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(vNetRG)
  name: 'vnet-mdmdev-swn'
}

resource Existing_Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: 'sn-mdmdev-privateendpoints1-swn'
  parent: Existing_VNET
}

module ServiceBus '../../../modules/deployServiceBus.bicep' = {
  scope: resourceGroup(deploymentRG)
  params: {
    ServiceBusSKU: ServiceBusSKU
    privateEndpointSubnetID: Existing_Subnet.id
    projectName: projectName
    regionAbbreviation: regionAbbreviation
  }
}

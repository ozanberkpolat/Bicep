targetScope = 'subscription'
import { OSType, vmSizeType } from '../../../modules/.shared/commonTypes.bicep'

param VMSize vmSizeType
param OS OSType
param regionAbbreviation string = 'usc'
param VMName string 
param vNetRG string
param deploymentRG string 


resource Existing_Vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(vNetRG)
  name: 'vnet-commonit-usc'
}

resource Existing_Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: 'sn-commonit-solarwinds-usc'
  parent: Existing_Vnet
}

module VM '../../../modules/deployVM.bicep' = {
  scope: resourceGroup(deploymentRG)
  params: {
    SizeOfVM: VMSize
    TypeofOS: OS
    VMName: VMName
    peSubnetResourceId: Existing_Subnet.id
    regionAbbreviation: regionAbbreviation
  }
}

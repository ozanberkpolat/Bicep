targetScope = 'subscription'
import { OSType, vmSizeType } from '../../../modules/.shared/commonTypes.bicep'

param VMSize vmSizeType
param OS OSType
param regionAbbreviation string = 'usc'
param VMName string 
param vNetRG string
param deploymentRG string
@description('Local administrator user name (required by the deployVM module).')
param adminUsername string
@description('Name of the existing VNet that holds the VM subnet.')
param vNetName string = 'vnet-contoso-usc'
@description('Name of the existing subnet the VM NIC joins.')
param subnetName string = 'sn-contoso-vm-usc'
@secure()
param adminPassword string


resource Existing_Vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(vNetRG)
  name: vNetName
}

resource Existing_Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: subnetName
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
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

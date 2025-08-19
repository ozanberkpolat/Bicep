targetScope = 'subscription'

// Importing necessary types
import { regionType } from '../../../modules/.shared/commonTypes.bicep'

param regionAbbreviation regionType
param projectName string
param vNetRg string
param subnetDelegation string
param existingPESubnet string
param CAEsubnetAddressSpace string
param vNetAddressSpace string
param newRGName string
param CAEsubnetDescription string
var deploymentName = 'DeployCAE3-${projectName}-${regionAbbreviation}'

resource Existing_RT 'Microsoft.Network/routeTables@2024-07-01' existing = {
  name: 'EXISTING-RT-NAME'
  scope: resourceGroup(vNetRg)
}

resource Existing_vNet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: 'EXISTING-VNET-NAME'
  scope: resourceGroup(vNetRg)
}

resource Existing_PE_Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: existingPESubnet
  parent: Existing_vNet
}

module NSG '../../../modules/deployNSG.bicep' = {
  scope: resourceGroup(vNetRg)
  params: {
    projectName:projectName
    regionAbbreviation: regionAbbreviation
    subnetAddressSpace: CAEsubnetAddressSpace
    vNetAddressSpace: vNetAddressSpace
  }
}

module Subnet '../../../modules/deploySubnet.bicep' = {
  scope: resourceGroup(vNetRg)
  params: {
    NSG_ID: NSG.outputs.NSGID
    RouteTable_ID: Existing_RT.id
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subnetAddressSpace: CAEsubnetAddressSpace
    subnetDescription: CAEsubnetDescription
    vNetName: Existing_vNet.name
    subnetDelegation: subnetDelegation
  }
}

module ResourceGroup '../../../modules/deployRG.bicep' = {
  params: {
    CostCenter: '1IT'
    Owner: 'ozan.polat@gunvorgroup.com'
    RGName: 'rg-cloudopstest-caetest-swn'
    regionAbbreviation: regionAbbreviation
    subscriptionId: 'SUBSCRIPTION-ID-HERE'
  }
}

module Log '../../../modules/deployLogAnalyticsWorkspace.bicep' = {
  scope: resourceGroup(newRGName)
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
  }
dependsOn: [
  ResourceGroup
]
}

module APPI '../../../modules/deployAppInsights.bicep' = {
  scope: resourceGroup(newRGName)
  params: {
    LogAnalyticsWorkspaceResourceId: Log.outputs.resource_ID
    projectName: projectName
    regionAbbreviation: regionAbbreviation
  }
}

module Get_LogAnalytics_SharedKey '../../../modules/.shared/get_LogAnalytics_SharedKey.bicep' = {
  scope: resourceGroup(newRGName)
  params: {
    logAnalyticsName: Log.outputs.Name
  }
}

module CAE '../../../modules/deployCAE.bicep' = {
  scope: resourceGroup(newRGName)
  name: deploymentName
  params: {
    peSubnetResourceId: Existing_PE_Subnet.id
    logAnalyticsWorkspaceId: Log.outputs.Workspace_ID
    sharedKey: Get_LogAnalytics_SharedKey.outputs.primarySharedKey
    appInsightsConnectionString: APPI.outputs.Connection_String
    infraSubnetId: Subnet.outputs.SubNetId
    projectName: projectName
    regionAbbreviation: regionAbbreviation
  }
}

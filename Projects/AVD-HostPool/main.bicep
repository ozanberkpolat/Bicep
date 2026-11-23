// Example: an AVD host pool with a Desktop app group, a workspace, an optional dedicated subnet and session hosts.
// Scope: resource group (the AVD management plane resource group).
//   az deployment group create -g <rg> -f main.bicep -p main.bicepparam
// Run `az deployment group what-if` first. The VNet must already exist.
targetScope = 'resourceGroup'

param hostPoolName string
param appGroupName string
param workspaceName string
param location string = 'westeurope'

@allowed([ 'Desktop', 'RemoteApp' ])
param appGroupType string = 'Desktop'
param remoteApps array = []
param userObjectIds array = []

@description('Resource group of the existing VNet. Empty skips the subnet and uses existingSubnetResourceId.')
param vNetResourceGroup string = ''
param vNetName string = ''
param subnetName string = 'snet-avd'
param subnetAddressPrefix string = '10.0.0.0/28'
param nextHopIpAddress string = ''
param existingSubnetResourceId string = ''

@description('0 deploys only the management plane.')
param sessionHostCount int = 0
param vmNamePrefix string = 'avd-sh'
param adminUsername string
@secure()
param adminPassword string = ''

var createSubnet = !empty(vNetResourceGroup)

module hostPool '../../Modules/deployAvdHostPool.bicep' = {
  name: 'avd-management-plane'
  params: {
    hostPoolName: hostPoolName
    appGroupName: appGroupName
    workspaceName: workspaceName
    location: location
    appGroupType: appGroupType
    remoteApps: remoteApps
    userObjectIds: userObjectIds
    createRegistrationToken: sessionHostCount > 0
  }
}

module subnet '../../Modules/deployAvdSubnet.bicep' = if (createSubnet) {
  name: 'avd-subnet'
  scope: resourceGroup(vNetResourceGroup)
  params: {
    vNetName: vNetName
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    nextHopIpAddress: nextHopIpAddress
  }
}

module sessionHosts '../../Modules/deployAvdSessionHost.bicep' = if (sessionHostCount > 0) {
  name: 'avd-session-hosts'
  params: {
    hostPoolName: hostPoolName
    location: resourceGroup().location
    subnetResourceId: createSubnet ? subnet!.outputs.subnetResourceId : existingSubnetResourceId
    sessionHostCount: sessionHostCount
    vmNamePrefix: vmNamePrefix
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
  dependsOn: [
    hostPool
  ]
}

output workspaceId string = hostPool.outputs.workspaceId
output hostPoolId string = hostPool.outputs.hostPoolId

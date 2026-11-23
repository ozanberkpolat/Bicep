// AVD RemoteApp lab: host pool + RemoteApp app group + workspace, a small VNet/subnet, one Entra-joined session
// host and user assignment (Desktop Virtualization User on the app group, Virtual Machine User Login on the VM).
// Built on Modules/deployAvdHostPool, deployAvdSubnet and deployAvdSessionHost.
// Scope: resource group.   az deployment group create -g <rg> -f main.bicep -p main.bicepparam
// UNTESTED: not deployed against a live subscription; run `az deployment group what-if` first.
//
// Lessons kept from the source lab:
//  - A separate host pool for RemoteApp: a user in both a Desktop and a RemoteApp group of the SAME host pool only
//    sees the preferred type. To show both side by side, deploy a Desktop pool too and pass its app group ID in
//    extraApplicationGroupIds (otherwise re-deploying the workspace detaches it).
//  - Entra-joined hosts need targetisaadjoined:i:1 (module default) and Virtual Machine User Login for the users.
//  - Only Win32 apps can be published by file path; Store apps (Notepad, Calculator on Windows 11) cannot.
//  - The registration token is created in this deployment (24 h) and consumed by the session host module.
//  - Auto-shutdown on the session host keeps a forgotten lab cheap.
targetScope = 'resourceGroup'

param location string = resourceGroup().location
@description('Region of the AVD service objects (metadata).')
param avdMetadataLocation string = 'westeurope'

param hostPoolName string
param appGroupName string
param workspaceName string

param remoteApps array = [
  {
    name: 'edge'
    friendlyName: 'Microsoft Edge'
    filePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe'
  }
  {
    name: 'powershell'
    friendlyName: 'Windows PowerShell'
    filePath: 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'
  }
]

@description('Entra group object IDs allowed to use the apps.')
param userObjectIds array
param extraApplicationGroupIds array = []

param vNetName string = 'vnet-avd-lab'
param vNetAddressPrefix string = '10.30.0.0/16'
param subnetAddressPrefix string = '10.30.1.0/24'

param vmNamePrefix string = 'avd-app'
param sessionHostCount int = 1
param vmSize string = 'Standard_D2s_v5'
param adminUsername string
@secure()
param adminPassword string

param shutdownTime string = '1900'
param shutdownTimeZone string = 'UTC'
param logAnalyticsWorkspaceId string = ''
param tags object = {
  purpose: 'lab'
}

// Built-in role: Virtual Machine User Login
var vmUserLoginRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'fb879df8-f326-4884-b1cf-06f3ad86be52'
)

module plane '../../Modules/deployAvdHostPool.bicep' = {
  name: 'avd-remoteapp-plane'
  params: {
    hostPoolName: hostPoolName
    appGroupName: appGroupName
    workspaceName: workspaceName
    location: avdMetadataLocation
    appGroupType: 'RemoteApp'
    maxSessionLimit: 4
    startVMOnConnect: false
    createRegistrationToken: true
    remoteApps: remoteApps
    userObjectIds: userObjectIds
    extraApplicationGroupIds: extraApplicationGroupIds
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vNetName
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [ vNetAddressPrefix ] }
  }
}

module subnet '../../Modules/deployAvdSubnet.bicep' = {
  name: 'avd-lab-subnet'
  params: {
    vNetName: vnet.name
    subnetName: 'snet-avd'
    subnetAddressPrefix: subnetAddressPrefix
    location: location
    tags: tags
  }
}

module hosts '../../Modules/deployAvdSessionHost.bicep' = {
  name: 'avd-remoteapp-hosts'
  params: {
    hostPoolName: hostPoolName
    location: location
    subnetResourceId: subnet.outputs.subnetResourceId
    sessionHostCount: sessionHostCount
    vmNamePrefix: vmNamePrefix
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    tags: tags
  }
  dependsOn: [ plane ]
}

// Users sign in to Entra-joined hosts only with this role (resource group scope covers every host).
resource vmLogin 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for id in userObjectIds: {
    name: guid(resourceGroup().id, id, vmUserLoginRoleId)
    properties: {
      roleDefinitionId: vmUserLoginRoleId
      principalId: id
      principalType: 'Group'
    }
  }
]

resource hostVm 'Microsoft.Compute/virtualMachines@2025-04-01' existing = [
  for i in range(1, sessionHostCount): {
    name: '${vmNamePrefix}-${i}'
  }
]

resource shutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = [
  for i in range(0, sessionHostCount): {
    name: 'shutdown-computevm-${vmNamePrefix}-${i + 1}'
    location: location
    tags: tags
    properties: {
      status: 'Enabled'
      taskType: 'ComputeVmShutdownTask'
      dailyRecurrence: { time: shutdownTime }
      timeZoneId: shutdownTimeZone
      targetResourceId: hostVm[i].id
      notificationSettings: { status: 'Disabled' }
    }
    dependsOn: [ hosts ]
  }
]

output workspaceId string = plane.outputs.workspaceId
output hostPoolId string = plane.outputs.hostPoolId
output sessionHosts array = hosts.outputs.sessionHostNames

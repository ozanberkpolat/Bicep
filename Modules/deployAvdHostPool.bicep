// This module deploys the Azure Virtual Desktop management plane: host pool, one application group
// (Desktop or RemoteApp), workspace, and optionally user assignment, published RemoteApps and diagnostics.
// Scope: resource group. Session hosts are NOT created here: deploy them with deployVM or deployVMStaticNic,
// join them with the registration token (see below).
//
// Lessons kept from the source deployments:
//  - One host pool serves ONE app group type. A user assigned to both a Desktop and a RemoteApp group on the same
//    host pool only sees the type in preferredAppGroupType. To show a desktop and apps side by side, deploy this
//    module twice (two host pools) and reference both app groups from one workspace.
//  - The workspace lists the app groups through applicationGroupReferences. Re-deploying a workspace with a shorter
//    list DETACHES the other groups, so pass every group the workspace must show in extraApplicationGroupIds.
//  - Redirection is controlled by customRdpProperty (an empty value after the colon disables a channel). Entra-joined
//    session hosts need targetisaadjoined:i:1.
//  - Agent updates run in a scheduled maintenance window (agentUpdate), not at random.
//  - The registration token is a secret. It is created here on request but never returned as an output; read it
//    afterwards with: az desktopvirtualization hostpool retrieve-registration-token (needs the desktopvirtualization
//    az extension) or Get-AzWvdHostPoolRegistrationToken.
//  - AVD metadata objects are only available in some regions; the default location is a metadata region.
// UNTESTED: not deployed against a live subscription; run `az deployment group what-if` first.

@description('Host pool name, for example hp-contoso-desktop-weu.')
param hostPoolName string

@description('Application group name, for example ag-contoso-desktop-weu.')
param appGroupName string

@description('Workspace name, for example ws-contoso-weu.')
param workspaceName string

@description('Region of the AVD service objects (metadata). Session hosts can live in another region.')
param location string = 'westeurope'

@allowed([ 'Desktop', 'RemoteApp' ])
param appGroupType string = 'Desktop'

@allowed([ 'Pooled', 'Personal' ])
param hostPoolType string = 'Pooled'

@description('Pooled only: DepthFirst fills one host before the next (cheaper), BreadthFirst spreads users.')
@allowed([ 'DepthFirst', 'BreadthFirst' ])
param loadBalancerType string = 'DepthFirst'

param maxSessionLimit int = 6

@description('Start a deallocated session host when a user connects. Needs the Desktop Virtualization Power On Contributor role for the AVD service principal.')
param startVMOnConnect bool = true

@description('RDP properties. Default: Entra-joined hosts, clipboard and drive redirection off, smart cards on.')
param customRdpProperty string = 'targetisaadjoined:i:1;audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectprinters:i:0;redirectcomports:i:0;redirectsmartcards:i:1;usbdevicestoredirect:s:;camerastoredirect:s:;screen mode id:i:2;'

@allowed([ 'Enabled', 'Disabled', 'EnabledForSessionHostsOnly', 'EnabledForClientsOnly' ])
param publicNetworkAccess string = 'Enabled'

@description('Agent update window, session host local time. dayOfWeek must be a full English day name.')
param agentUpdateDayOfWeek string = 'Sunday'
param agentUpdateHour int = 12

@description('Create a registration token for session hosts. Re-deploying with true replaces the token.')
param createRegistrationToken bool = false
param registrationTokenValidHours int = 24
param baseTime string = utcNow()

param hostPoolFriendlyName string = hostPoolName
param appGroupFriendlyName string = appGroupName
param workspaceFriendlyName string = workspaceName

@description('Entra object IDs (groups recommended) granted Desktop Virtualization User on the app group.')
param userObjectIds array = []

@allowed([ 'Group', 'User' ])
param userPrincipalType string = 'Group'

@description('RemoteApp only: [{ name: \'edge\', friendlyName: \'Microsoft Edge\', filePath: \'C:\\\\Program Files (x86)\\\\Microsoft\\\\Edge\\\\Application\\\\msedge.exe\' }]. Win32 apps only; Store apps need a start menu app instead.')
param remoteApps array = []

@description('Other app group resource IDs the workspace must keep listing (see header).')
param extraApplicationGroupIds array = []

@description('Log Analytics workspace resource ID. Empty skips diagnostics.')
param logAnalyticsWorkspaceId string = ''

param tags object = {}

// Built-in role: Desktop Virtualization User
var desktopVirtualizationUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
)

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    friendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: hostPoolType == 'Pooled' ? loadBalancerType : 'Persistent'
    maxSessionLimit: hostPoolType == 'Pooled' ? maxSessionLimit : null
    personalDesktopAssignmentType: hostPoolType == 'Personal' ? 'Automatic' : null
    preferredAppGroupType: appGroupType == 'RemoteApp' ? 'RailApplications' : 'Desktop'
    startVMOnConnect: startVMOnConnect
    validationEnvironment: false
    publicNetworkAccess: publicNetworkAccess
    customRdpProperty: customRdpProperty
    agentUpdate: {
      type: 'Scheduled'
      useSessionHostLocalTime: true
      maintenanceWindows: [
        {
          dayOfWeek: agentUpdateDayOfWeek
          hour: agentUpdateHour
        }
      ]
    }
    registrationInfo: createRegistrationToken
      ? {
          expirationTime: dateTimeAdd(baseTime, 'PT${registrationTokenValidHours}H')
          registrationTokenOperation: 'Update'
        }
      : {
          registrationTokenOperation: 'None'
        }
  }
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    friendlyName: appGroupFriendlyName
    applicationGroupType: appGroupType
    hostPoolArmPath: hostPool.id
  }
}

resource apps 'Microsoft.DesktopVirtualization/applicationGroups/applications@2025-10-10' = [
  for app in (appGroupType == 'RemoteApp' ? remoteApps : []): {
    parent: appGroup
    name: app.name
    properties: {
      friendlyName: app.?friendlyName ?? app.name
      description: app.?description ?? ''
      applicationType: 'InBuilt'
      filePath: app.filePath
      iconPath: app.?iconPath ?? app.filePath
      iconIndex: 0
      commandLineSetting: 'DoNotAllow'
      showInPortal: true
    }
  }
]

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2025-10-10' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: workspaceFriendlyName
    publicNetworkAccess: publicNetworkAccess == 'Disabled' ? 'Disabled' : 'Enabled'
    applicationGroupReferences: union([ appGroup.id ], extraApplicationGroupIds)
  }
}

resource userAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for objectId in userObjectIds: {
    name: guid(appGroup.id, objectId, desktopVirtualizationUserRoleId)
    scope: appGroup
    properties: {
      roleDefinitionId: desktopVirtualizationUserRoleId
      principalId: objectId
      principalType: userPrincipalType
    }
  }
]

resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${hostPoolName}-diag'
  scope: hostPool
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
output appGroupId string = appGroup.id
output workspaceId string = workspace.id

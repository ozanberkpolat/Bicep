// Identity baseline: user-assigned managed identities (UAMI) plus RBAC at subscription and resource group scope.
// Scope: subscription.
//   az deployment sub create --location <region> -f main.bicep -p main.bicepparam
//
// NOT covered here (Bicep cannot create Entra objects): Entra groups, PIM eligibility, Conditional Access, app
// registrations. Create the groups first (portal, Graph PowerShell), then put their object IDs in the .bicepparam.
//
// Lessons kept from the source:
//  - Role assignment names are guid(scope, principal, role): deterministic, so a re-deploy is idempotent.
//  - A new Entra group or UAMI may not be replicated yet when the assignment runs; the principalType property
//    (Group / ServicePrincipal) avoids the "PrincipalNotFound" race, so always set it.
//  - Needs Owner or User Access Administrator on the scope (PIM activation if your role is eligible only).
targetScope = 'subscription'

@description('Short organisation prefix (2-9 chars) used in resource names.')
@minLength(2)
@maxLength(9)
param orgPrefix string

param location string

@allowed([ 'dev', 'test', 'uat', 'prod' ])
param environmentName string

param costCenter string
param ownerTeam string
param ownerEmail string
param changeTicket string = 'N/A'

@description('Existing resource group that receives the managed identities.')
param identityResourceGroupName string

@description('Each entry: { workload: \'pipeline\', description: \'CI/CD deployment identity\' }')
param managedIdentities array = []

@description('Subscription-level assignments. Each: { principalId, roleDefinitionId, principalType, description }. roleDefinitionId is the built-in role GUID.')
param subscriptionRoleAssignments array = []

@description('Resource group assignments. Each: { resourceGroupName, principalId, roleDefinitionId, principalType, description }.')
param resourceGroupRoleAssignments array = []

param additionalTags object = {}

var regionCodeMap = {
  germanywestcentral: 'gwc'
  westeurope: 'weu'
  northeurope: 'neu'
  eastus: 'eus'
  westus2: 'wus2'
  uksouth: 'uks'
  francecentral: 'frc'
  switzerlandnorth: 'chn'
  norwayeast: 'noe'
}
var regionCode = regionCodeMap[?location] ?? location

var tags = union(
  {
    organisation: orgPrefix
    environment: environmentName
    costCenter: costCenter
    ownerTeam: ownerTeam
    ownerEmail: ownerEmail
    changeTicket: changeTicket
    workload: 'identity'
    managedBy: 'Bicep'
  },
  additionalTags
)

// Built-in role definition GUIDs (same in every tenant).
// https://learn.microsoft.com/azure/role-based-access-control/built-in-roles
// Owner 8e3af657-a8ff-443c-a75c-2fe8c4bcb635, Contributor b24988ac-6180-42a0-ab88-20f7382dd24c,
// Reader acdd72a7-3385-48ef-bd42-f606fba81ae7, User Access Administrator 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9,
// Key Vault Secrets User 4633458b-17de-408a-b874-0445c86b69e6, Storage Blob Data Reader 2a2b9908-6ea1-4ae2-8e65-a410df84e7d1,
// Monitoring Reader 43d0d8ad-25c7-4714-9337-8ba259a9fe05, Managed Identity Operator f1a07417-d97a-45cb-824c-7a7467783830

module uamis 'modules/managed-identities.bicep' = if (!empty(managedIdentities)) {
  name: 'uami-${orgPrefix}-${environmentName}'
  scope: resourceGroup(identityResourceGroupName)
  params: {
    orgPrefix: orgPrefix
    environmentName: environmentName
    regionCode: regionCode
    location: location
    managedIdentities: managedIdentities
    tags: tags
  }
}

resource subRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in subscriptionRoleAssignments: {
    name: guid(subscription().id, a.principalId, a.roleDefinitionId)
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleDefinitionId)
      principalId: a.principalId
      principalType: a.principalType
      description: a.?description ?? ''
    }
  }
]

module rgRoleAssignments 'modules/rg-role-assignments.bicep' = [
  for a in resourceGroupRoleAssignments: {
    name: 'rbac-${a.resourceGroupName}-${uniqueString(a.principalId, a.roleDefinitionId)}'
    scope: resourceGroup(a.resourceGroupName)
    params: {
      principalId: a.principalId
      roleDefinitionId: a.roleDefinitionId
      principalType: a.principalType
      assignmentDescription: a.?description ?? ''
    }
  }
]

output identities array = !empty(managedIdentities) ? uamis!.outputs.identities : []

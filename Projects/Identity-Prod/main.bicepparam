using './main.bicep'

param orgPrefix = 'contoso'
param location = 'westeurope'
param environmentName = 'prod'
param costCenter = 'CC-001'
param ownerTeam = 'Cloud Platform Team'
param ownerEmail = 'cloudteam@contoso.com'
param changeTicket = 'CHG-0001'

// Existing resource group for the identities
param identityResourceGroupName = 'rg-contoso-security-weu'

// UAMI names: <orgPrefix>-<workload>-uami-<env>-<regionCode>, for example contoso-pipeline-uami-prod-weu
param managedIdentities = [
  { workload: 'pipeline', description: 'CI/CD deployment identity' }
  { workload: 'backup', description: 'Backup automation identity' }
]

// Placeholder object IDs: replace with the real Entra group IDs
param subscriptionRoleAssignments = [
  {
    principalId: '00000000-0000-0000-0000-000000000001'
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
    principalType: 'Group'
    description: 'Cloud team: Reader on the subscription'
  }
]

param resourceGroupRoleAssignments = [
  {
    resourceGroupName: 'rg-contoso-security-weu'
    principalId: '00000000-0000-0000-0000-000000000002'
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    principalType: 'Group'
    description: 'Platform admins: Contributor on the security resource group'
  }
]

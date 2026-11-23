// Resource organisation baseline: resource groups with a naming standard and a standard tag set, plus policy that
// requires those tags on resource groups. Scope: subscription.
//   az deployment sub create --location <region> -f main.bicep -p main.bicepparam
//
// Naming:  <orgPrefix>-<workload>-rg-<env>-<regionCode>      e.g. contoso-network-rg-prod-gwc (prefix 2-9 chars)
// Lessons kept from the source:
//  - Resource group names cannot be changed later; decide the pattern before the first deployment.
//  - The tag policy is a built-in definition (Require a tag on resource groups). It audits/denies on creation and
//    does not tag existing groups. Policy assignment needs Resource Policy Contributor or Owner on the subscription.
//  - additionalTags wins over the standard tags on a key collision (union order).
//  - Optional groups (management, network, security) are switched by flags; compute, storage and devops always exist.
targetScope = 'subscription'

@description('Short prefix that identifies the organisation, used in all names.')
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

@description('Value of the deployedBy tag (team or company that ran the deployment).')
param deployedBy string = 'platform-team'

param deployManagement bool = true
param deployNetwork bool = true
param deploySecurity bool = true

@description('Create the three tag-required policy assignments.')
param enforceRequiredTags bool = true

@description('Tag names the policy requires on every resource group.')
param requiredTagNames array = [
  'costCenter'
  'environment'
  'ownerTeam'
]

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

var rgNames = {
  management: '${orgPrefix}-management-rg-${environmentName}-${regionCode}'
  network: '${orgPrefix}-network-rg-${environmentName}-${regionCode}'
  security: '${orgPrefix}-security-rg-${environmentName}-${regionCode}'
  compute: '${orgPrefix}-compute-rg-${environmentName}-${regionCode}'
  storage: '${orgPrefix}-storage-rg-${environmentName}-${regionCode}'
  devops: '${orgPrefix}-devops-rg-${environmentName}-${regionCode}'
}

var tags = union(
  {
    organisation: orgPrefix
    environment: environmentName
    region: location
    costCenter: costCenter
    ownerTeam: ownerTeam
    ownerEmail: ownerEmail
    changeTicket: changeTicket
    managedBy: 'Bicep'
    deployedBy: deployedBy
  },
  additionalTags
)

resource rgManagement 'Microsoft.Resources/resourceGroups@2024-03-01' = if (deployManagement) {
  name: rgNames.management
  location: location
  tags: union(tags, { workload: 'management', tier: 'platform' })
}

resource rgNetwork 'Microsoft.Resources/resourceGroups@2024-03-01' = if (deployNetwork) {
  name: rgNames.network
  location: location
  tags: union(tags, { workload: 'network', tier: 'platform' })
}

resource rgSecurity 'Microsoft.Resources/resourceGroups@2024-03-01' = if (deploySecurity) {
  name: rgNames.security
  location: location
  tags: union(tags, { workload: 'security', tier: 'platform' })
}

resource rgCompute 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNames.compute
  location: location
  tags: union(tags, { workload: 'compute', tier: 'workload' })
}

resource rgStorage 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNames.storage
  location: location
  tags: union(tags, { workload: 'storage', tier: 'workload' })
}

resource rgDevOps 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNames.devops
  location: location
  tags: union(tags, { workload: 'devops', tier: 'platform' })
}

// Built-in policy definition "Require a tag on resource groups"
var requireTagOnRgPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'

resource requireTag 'Microsoft.Authorization/policyAssignments@2024-04-01' = [
  for tagName in (enforceRequiredTags ? requiredTagNames : []): {
    name: take('${orgPrefix}-require-${toLower(tagName)}-tag', 64)
    properties: {
      displayName: '[${toUpper(orgPrefix)}] Require ${tagName} tag on resource groups'
      description: 'Resource groups must carry the ${tagName} tag.'
      policyDefinitionId: requireTagOnRgPolicyId
      parameters: {
        tagName: {
          value: tagName
        }
      }
      enforcementMode: 'Default'
    }
  }
]

output resourceGroupNames object = {
  management: deployManagement ? rgManagement.name : 'not deployed'
  network: deployNetwork ? rgNetwork.name : 'not deployed'
  security: deploySecurity ? rgSecurity.name : 'not deployed'
  compute: rgCompute.name
  storage: rgStorage.name
  devops: rgDevOps.name
}
output appliedTags object = tags

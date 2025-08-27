// This module deploys a Route Table

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param peSubnetResourceId string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Get the Private DNS Zone mapping
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

var Name = naming.outputs.Resources.containerRegistry
var PE = naming.outputs.privateEndpoints.pe_acr
var NIC = naming.outputs.NICs.pe_acr_nic

module ContainerRegistry 'br/public:avm/res/container-registry/registry:0.9.2' = {
  params: {
    name: Name
    location:location.region
    dataEndpointEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
    acrSku:'Premium'
    acrAdminUserEnabled:true
    retentionPolicyDays: 7
    softDeletePolicyDays: 7
    softDeletePolicyStatus: 'enabled'
    trustPolicyStatus: 'disabled'
    quarantinePolicyStatus:'disabled'
    exportPolicyStatus: 'enabled'
    managedIdentities:{
      systemAssigned:true
    }
    privateEndpoints: [
      {
        subnetResourceId: peSubnetResourceId
        name: PE
        service: 'registry'
        ipConfigurations: []
        privateLinkServiceConnectionName: PE
        customNetworkInterfaceName: NIC
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: PrivateDNSZones.acr.configName
              privateDnsZoneResourceId: PrivateDNSZones.acr.dnsZone
            }
          ]
        }
      }
    ]
  }
}

// This module deploys a KeyVault with Private Endpoint

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param peSubnetResourceId string

// Variables 
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

var Name = naming.outputs.Resources.keyVault
var PE = naming.outputs.privateEndpoints.pe_keyVault
var NIC = naming.outputs.NICs.pe_keyVault_nic


// Deploy Key Vault with Private Endpoint
module Key_Vault 'br/public:avm/res/key-vault/vault:0.13.1' = {
  params: {
    name: Name
    location: location.region
    sku: 'standard'
    accessPolicies:[]
    publicNetworkAccess: 'Disabled'
    enablePurgeProtection: true
    enableSoftDelete: true
    enableVaultForDeployment: false
    enableVaultForTemplateDeployment: false
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 90
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    
    privateEndpoints: [
      {
        subnetResourceId: peSubnetResourceId
        name: PE
        service: 'vault'
        ipConfigurations: []
        privateLinkServiceConnectionName: PE
        customNetworkInterfaceName: NIC
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: PrivateDNSZones.keyvault.configName
              privateDnsZoneResourceId: PrivateDNSZones.keyvault.dnsZone
            }
          ]

        }
      }
    ]
  }

}

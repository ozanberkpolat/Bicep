// This module deploys a KeyVault with Private Endpoint

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param privateEndpointSubnetID string

// Variables 
var deploymentName = 'DeployKV-${projectName}-${regionAbbreviation}'
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

// Deploy Key Vault with Private Endpoint
module Key_Vault 'br/public:avm/res/key-vault/vault:0.13.1' = {
  name: deploymentName
  params: {
    name: naming.outputs.keyVaultName
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
        subnetResourceId: privateEndpointSubnetID
        name: naming.outputs.pe_keyVault
        service: 'vault'
        ipConfigurations: []
        privateLinkServiceConnectionName: naming.outputs.pe_keyVault
        customNetworkInterfaceName: naming.outputs.pe_keyVault_nic
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

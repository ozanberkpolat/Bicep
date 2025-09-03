// This module deploys a Cosmos DB

// Importing necessary types
import { regionType, regionDefinitionType, getLocation, CDBType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param peSubnetResourceId string
param CosmosDBType CDBType

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

var Name = naming.outputs.Resources.CosmosDb
var PE = naming.outputs.privateEndpoints.pe_cdb
var NIC = naming.outputs.NICs.pe_cdb_nic
var Service = CosmosDBType == 'Sql' ? 'Sql' : CosmosDBType == 'MongoDB' ? 'MongoDB' : 'Sql'

module CosmosDB 'br/public:avm/res/document-db/database-account:0.15.1' = {
  params: {
    name: Name
    enableMultipleWriteLocations: false
    disableKeyBasedMetadataWriteAccess: true
    enableFreeTier: false
    enableAnalyticalStorage: false
    databaseAccountOfferType: 'Standard'
    disableLocalAuthentication: true
    minimumTlsVersion: 'Tls12'
    location: location.region
    failoverLocations:[
      {
        failoverPriority: 0
        locationName: 'Switzerland North'
        isZoneRedundant: true
      }
    ]
    backupPolicyType: 'Continuous'
    backupPolicyContinuousTier:'Continuous30Days'
    privateEndpoints: [
      {
        subnetResourceId: peSubnetResourceId
        name: PE
        service: Service
        ipConfigurations: []
        privateLinkServiceConnectionName: PE
        customNetworkInterfaceName: NIC
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              name: PrivateDNSZones.cosmos.configName
              privateDnsZoneResourceId: PrivateDNSZones.cosmos.dnsZone
            }
          ]
        }
      }
    ]
  }
}

output ResourceId string = CosmosDB.outputs.resourceId

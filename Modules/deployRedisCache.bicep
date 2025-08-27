// This module deploys a Route Table

// Importing necessary types
import { regionType, regionDefinitionType, SKUType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param RedissubnetResourceId string
param peSubnetResourceId string
param sku SKUType

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

var Name = naming.outputs.Resources.redisCache
var PE = naming.outputs.privateEndpoints.pe_redis
var NIC = naming.outputs.NICs.pe_redis_nic

module Redis 'br/public:avm/res/cache/redis:0.16.3' = {
  params: {
    name: Name
    location: location.region
    skuName: sku
    publicNetworkAccess: 'Disabled'
    capacity: 1
    disableAccessKeyAuthentication: true
    minimumTlsVersion: '1.2'
    managedIdentities: {
      systemAssigned:true
    }
    redisVersion: '6'
    subnetResourceId:RedissubnetResourceId
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
              name: PrivateDNSZones.redis.configName
              privateDnsZoneResourceId: PrivateDNSZones.redis.dnsZone
            }
          ]

        }
      }
    ]
  }
}

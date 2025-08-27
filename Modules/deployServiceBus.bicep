// This module deploys a Route Table

// Importing necessary types
import { regionType, SKUType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param privateEndpointSubnetID string
param ServiceBusSKU SKUType

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

// Variables 
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

var Name = naming.outputs.Resources.serviceBus
var PE = naming.outputs.privateEndpoints.pe_serviceBus
var NIC = naming.outputs.NICs.pe_servicebus_nic

module AzureServiceBus 'br/public:avm/res/service-bus/namespace:0.15.0' = {
  params: {
    name: Name
    publicNetworkAccess: 'Disabled'
    location: location.region
    minimumTlsVersion: '1.2'
    disableLocalAuth: true
    premiumMessagingPartitions: ( ServiceBusSKU == 'Premium' ) ? 1 : null
    skuObject: {
      name: ServiceBusSKU
      capacity: ( ServiceBusSKU == 'Premium' ) ? 1 : null
    }
    managedIdentities: {
      systemAssigned: true
    }
  }
}

module Private_Endpoint 'br/public:avm/res/network/private-endpoint:0.11.0' = {
  params: {
    name: PE
    subnetResourceId: privateEndpointSubnetID
    customNetworkInterfaceName: NIC
    privateLinkServiceConnections: [
      {
        name: PE
        properties: {
          groupIds: ['namespace']
          privateLinkServiceId: AzureServiceBus.outputs.resourceId
        }
      }
    ]
    privateDnsZoneGroup: {
      privateDnsZoneGroupConfigs: [
        {
          privateDnsZoneResourceId: PrivateDNSZones.servicebus.dnsZone
          name: PrivateDNSZones.servicebus.configName
        }
      ]
    }
  }
}

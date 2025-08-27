// This module deploys an Azure Data Factory (ADF) with private endpoint connectivity

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param PEsubNetId string

// Importing shared resources and configurations
var PrivateDNSZones = json(loadTextContent('.shared/privatednszones.json'))
var PEServices = loadJsonContent('.shared/pe_services.json')

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

var Name = naming.outputs.Resources.dataFactory
var PE_Portal = naming.outputs.privateEndpoints.pe_adf_portal
var PE_ADF = naming.outputs.privateEndpoints.pe_adf_datafactory
var NIC_Portal = naming.outputs.NICs.pe_adf_portal_nic
var NIC_ADF = naming.outputs.NICs.pe_adf_datafactory_nic

// Azure Data Factory deployment
module Create_ADF 'br/public:avm/res/data-factory/factory:0.10.4' = {
  params:{
    name: Name
    location: location.region
    publicNetworkAccess: 'Disabled'
    managedIdentities: {
      systemAssigned: true
    }
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.datafactory.dnsZone
            }
          ]
        }
        service: PEServices.datafactory_datafactory.service
        subnetResourceId: PEsubNetId
        name: PE_ADF
        customNetworkInterfaceName:NIC_ADF
      }
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.datafactory.dnsZone
            }
          ]
        }
        service: PEServices.datafactory_portal.service
        subnetResourceId: PEsubNetId
        name: PE_Portal
        customNetworkInterfaceName: NIC_Portal
      }
    ]
  }
}


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

// Azure Data Factory deployment
module Create_ADF 'br/public:avm/res/data-factory/factory:0.10.4' = {
  params:{
    name: naming.outputs.dataFactoryName
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
        name: naming.outputs.pe_adf_datafactory
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
        name: naming.outputs.pe_adf_portal
      }
    ]
  }
}


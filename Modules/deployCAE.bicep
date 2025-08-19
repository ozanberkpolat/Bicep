// This module deploys a Route Table

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param infraSubnetId string
param appInsightsConnectionString string
param logAnalyticsWorkspaceId string
@secure()
param sharedKey string
param peSubnetResourceId string

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region
var deploymentName = 'DeployCAE-${projectName}-${regionAbbreviation}'
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

module Deploy_CAE 'br/public:avm/res/app/managed-environment:0.11.3' = {
  name: deploymentName
  params: {
    name: naming.outputs.ContainerAppEnv
    location: location
    publicNetworkAccess: 'Disabled'
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceId
        sharedKey: sharedKey
      }
    }
    appInsightsConnectionString: appInsightsConnectionString
    internal: true
    managedIdentities: {
      systemAssigned: true
    }
    infrastructureSubnetResourceId: infraSubnetId
    infrastructureResourceGroupName: ''
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
        enableFips: false
      }
    ]
  }
}

module PE 'br/public:avm/res/network/private-endpoint:0.11.0' = {
  params: {
    name: naming.outputs.pe_cae
    subnetResourceId: peSubnetResourceId
    privateLinkServiceConnections: [
      {
        name: naming.outputs.pe_cae
        properties: {
          groupIds: ['managedEnvironments']
          privateLinkServiceId: Deploy_CAE.outputs.resourceId
        }
      }
    ]
    privateDnsZoneGroup: {
      privateDnsZoneGroupConfigs: [
        {
          privateDnsZoneResourceId: PrivateDNSZones.containerapp.dnsZone
          name: PrivateDNSZones.containerapp.configName
        }
      ]
    }
  }
}

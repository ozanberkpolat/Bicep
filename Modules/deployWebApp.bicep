// This module deploys a Function App to an existing App Service Plan

// Importing necessary types
import { regionType, SitesOSType, RunTimeType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param peSubnetResourceId string
param outboundSubnetID string
param appServicePlanId string
param osType SitesOSType
param RuntimeStack RunTimeType
param RuntimeVersion string
param regionAbbreviation regionType
param AppInsightsResourceId string
param storageAccountResourceId string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Other Variables
var kind = (osType == 'Linux') ? 'app,linux' : 'app'
var linuxFxVersion = '${toUpper(RuntimeStack)}|${RuntimeVersion}'
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

var Name = naming.outputs.Resources.webApp
var PE = naming.outputs.privateEndpoints.pe_web
var NIC = naming.outputs.NICs.pe_web_nic

module WebApp 'br/public:avm/res/web/site:0.19.0' = {
  params: {
    name: Name
    location: location.region
    kind: kind
    serverFarmResourceId: appServicePlanId
    hyperV: false
    managedIdentities: {
      systemAssigned: true
    }
    hostNameSslStates:[
      {
        name: '${Name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${Name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    dnsConfiguration:{}
    scmSiteAlsoStopped: false
    clientCertEnabled: false
    containerSize: 1536
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    storageAccountRequired: false
    virtualNetworkSubnetResourceId: outboundSubnetID
    dailyMemoryTimeQuota: 0
    enabled: true
    configs: [
      {
        name: 'appsettings'
        applicationInsightResourceId: AppInsightsResourceId
        storageAccountResourceId: storageAccountResourceId
        storageAccountUseIdentityAuthentication: true
      }
    ]
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: (osType == 'Linux') ? linuxFxVersion : ''
      netFrameworkVersion: 'v${RuntimeVersion}'
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
    }
    // Private Endpoint and Publishing Credentials config
  privateEndpoints: [
    {
      
      name: PE
      subnetResourceId: peSubnetResourceId
      privateLinkServiceConnectionName: PE
      customNetworkInterfaceName: NIC
      privateDnsZoneGroup: {
        privateDnsZoneGroupConfigs: [
          {
            privateDnsZoneResourceId: PrivateDNSZones.web.dnsZone
            name: PrivateDNSZones.web.configName
          }
        ]
      }
    }
  ]
  basicPublishingCredentialsPolicies:[
    {
      name: 'ftp'
      allow: false
    }
    {
      name: 'scm'
      allow: false
    }
  ]
  outboundVnetRouting: {
    allTraffic: true
  }
  }
}

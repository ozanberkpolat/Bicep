// This module deploys a Function App to an existing App Service Plan

// Importing necessary types
import { regionType, SitesOSType, RunTimeType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param peSubnetResourceId string
param outboundSubnetID string
param appServicePlanId string
param storageAccountName string
param osType SitesOSType
param RuntimeStack RunTimeType
param RuntimeVersion string
param regionAbbreviation regionType
param AppInsightsResourceId string
param storageAccountResourceId string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

var Name = naming.outputs.Resources.functionApp
var PE = naming.outputs.privateEndpoints.pe_func
var NIC = naming.outputs.NICs.pe_func_nic

// Assigning the name to a variable for general
var functionAppName = Name

// Other Variables
var kind = (osType == 'Linux') ? 'functionapp,linux' : 'functionapp'
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

module FunctionApp 'br/public:avm/res/web/site:0.19.0' = {
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
        name: '${functionAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
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
      netFrameworkVersion: (RuntimeStack == 'Dotnet') ? RuntimeVersion : ''
      powerShellVersion: (RuntimeStack == 'Powershell') ? RuntimeVersion : ''
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountResourceId, '2022-09-01').keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: (RuntimeStack == 'Dotnet') ? 'dotnet-isolated' : toLower(RuntimeStack)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
    enabled: true
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

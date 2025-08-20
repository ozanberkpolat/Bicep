// This module deploys a Function App to an existing App Service Plan

// Importing necessary types
import { regionType, SitesOSType, RunTimeType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param vNetName string
param vNetRG string
param peSubnetName string
param outboundSubnetID string
param appServicePlanId string
param storageAccountName string
param storageAccountId string
param osType SitesOSType
param RuntimeStack RunTimeType
param RuntimeVersion string
param regionAbbreviation regionType
param AppInsightsResourceId string
param storageAccountResourceId string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

var functionAppName = naming.outputs.functionApp

// Other Variables
var kind = (osType == 'Linux') ? 'functionapp,linux' : 'functionapp'
var linuxFxVersion = '${toUpper(RuntimeStack)}|${RuntimeVersion}'
var PeSubnetID = 'subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetRG}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${peSubnetName}'
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))
var deploymentName = 'DeployFunc-${projectName}-${regionAbbreviation}'


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
  name: deploymentName
  params: {
    name: naming.outputs.functionApp
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
      linuxFxVersion: linuxFxVersion
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2022-09-01').keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: toLower(RuntimeStack)
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
      
      name: naming.outputs.pe_func
      subnetResourceId: PeSubnetID
      privateLinkServiceConnectionName: naming.outputs.functionApp
      customNetworkInterfaceName: naming.outputs.pe_func_nic
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

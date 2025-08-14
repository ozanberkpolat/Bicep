// This module deploys a Function App to an existing App Service Plan

// Importing necessary types
import { regionType, OSType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param vNetName string
param vNetRG string
param peSubnetName string
param outboundSubnetID string
param appServicePlanId string
param storageAccountName string
param storageAccountId string
param osType OSType

@allowed([
  'Dotnet'
  'Python'
])
param RuntimeStack string
param RuntimeVersion string
param regionAbbreviation regionType

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Variables for naming conventions
var functionAppName = 'func-${projectName}-${regionAbbreviation}'
var peName = 'pe-func-${projectName}-${regionAbbreviation}'

// Other Variables
var FunctionAppID = functionApp.id
var kind = ((osType == 'Linux') ? 'functionapp,linux' : ((osType == 'Windows') ? 'functionapp' : ''))
var reserved = ((osType == 'Linux') ? true : ((osType == 'Windows') ? false : null))
var linuxFxVersion = '${RuntimeStack}|${RuntimeVersion}'
var PeSubnetID = 'subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetRG}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${peSubnetName}'
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

// Deploy FUnction App
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
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
    serverFarmId: appServicePlanId
    reserved: reserved
    isXenon: false
    hyperV: false
    dnsConfiguration: {}
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    vnetBackupRestoreEnabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Disabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
    virtualNetworkSubnetId: outboundSubnetID
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
  }
}

resource functionAppName_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: functionApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource functionAppName_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: functionApp
  name: 'scm'
  properties: {
    allow: false
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: peName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: peName
        properties: {
          privateLinkServiceId: FunctionAppID
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${peName}-nic'
    subnet: {
      id: PeSubnetID
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource peName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.azurewebsites.azure.net'
        properties: {
          privateDnsZoneId: PrivateDNSZones.web.dnsZone
        }
      }
    ]
  }
}

resource functionAppName_vnet 'Microsoft.Web/sites/virtualNetworkConnections@2024-04-01' = {
  parent: functionApp
  name: 'vnet'
  properties: {
    vnetResourceId: outboundSubnetID 
    isSwift: true
  }
}


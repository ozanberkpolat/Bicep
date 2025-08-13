@maxLength(18)
param projectName string
param vNetName string
param vNetRG string
param peSubnetName string
param subscriptionId string

@minLength(1)
param serviceEndpoints array = [
  'blob'
  'file'
  'table'
  'queue'
]

import { regionType } from '.shared/commonTypes.bicep'
param regionAbbreviation regionType

import { storageAccountKind } from '.shared/commonTypes.bicep'
param SAKind storageAccountKind = 'StorageV2' // Default to StorageV2


var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  scope: subscription(subscriptionId)
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

// Variables
var storageAccountName = 'gun${projectName}${regionAbbreviation}'
var subnetId = 'subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetRG}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${peSubnetName}'
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))
var groupIds = {
  blob: 'blob'
  file: 'file'
  table: 'table'
  queue: 'queue'
}

var endpointNames = {
  blob: 'pe-${storageAccountName}-blob-${regionAbbreviation}'
  file: 'pe-${storageAccountName}-file-${regionAbbreviation}'
  table: 'pe-${storageAccountName}-table-${regionAbbreviation}'
  queue: 'pe-${storageAccountName}-queue-${regionAbbreviation}'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: SAKind
  properties: {
    allowedCopyScope: 'PrivateLink'
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: false
    supportsHttpsTrafficOnly: true
    isHnsEnabled: SAKind == 'BlobStorage'
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}
var StorageAccountID string = storageAccount.id

resource storageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/fileServices@2023-04-01' = if (SAKind == 'FileStorage' || SAKind == 'StorageV2') {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Private endpoints
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-11-01' = [for svc in serviceEndpoints: {
  name: endpointNames[svc]
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: endpointNames[svc]
        properties: {
          privateLinkServiceId: StorageAccountID
          groupIds: [
            groupIds[svc]
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
    customNetworkInterfaceName: '${endpointNames[svc]}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}]

// Private DNS zone groups
resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = [for (svc, i) in serviceEndpoints: {
  parent: privateEndpoints[i]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateDNSZones[svc].configName
        properties: {
          privateDnsZoneId: PrivateDNSZones[svc].dnsZone
        }
      }
    ]
  }
}]

output SAID string = storageAccount.id
output SAName string = storageAccount.name


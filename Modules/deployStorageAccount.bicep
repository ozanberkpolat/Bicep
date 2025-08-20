// This module deploys a Storage Account with the private endpoints of the services your choice
// Importing necessary types
import { regionType, storageAccountKind, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
@maxLength(18)
param projectName string
param vNetName string
param vNetRG string
param peSubnetName string

@minLength(1)
param serviceEndpoints array = [
  'blob'
  'file'
  'table'
  'queue'
]

param regionAbbreviation regionType
param SAKind storageAccountKind = 'StorageV2' // Default to StorageV2

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

// Importing shared resources and configurations
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))


// Variables
var storageAccountName = 'gun${projectName}${regionAbbreviation}'
var subnetId = 'subscriptions/${subscription().subscriptionId}/resourceGroups/${vNetRG}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${peSubnetName}'
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

// Deploy Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location.region
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

// Configure Blob Retention 
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

// Configure File Retention
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

// Deploy Private Endpoints
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-11-01' = [for svc in serviceEndpoints: {
  name: endpointNames[svc]
  location: location.region
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

// Private DNS zone config
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

output ResourceId string = storageAccount.id
output Name string = storageAccount.name


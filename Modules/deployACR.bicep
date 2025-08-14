// This module deploys an Azure Container Registry (ACR) with private endpoint connectivity

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string

// Variables for naming conventions
var vnetRGName = 'rg-vnet-${projectName}-${regionAbbreviation}'
var vnetName = 'vnet-${projectName}-${regionAbbreviation}'
var subnetName = 'sn-${projectName}-pe-${regionAbbreviation}' 
var acrName = 'cr${projectName}${regionAbbreviation}'

// Loading shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region
var PrivateDNSZones = json(loadTextContent('.shared/privateDnsZones.json'))

// Discovering existing vNet
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRGName)
}

// Discovering existing subnet
// This subnet is expected to be located in the vNet defined above
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetName
  parent: vnet
}

// Azure Container Registry deployment
module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: 'acrDeployment-${acrName}'
  params: {
    name: acrName
    acrAdminUserEnabled: false
    acrSku: 'Premium'
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    exportPolicyStatus: 'enabled'
    location: location
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        subnetResourceId: subnet.id
        name: 'pe-${acrName}-${regionAbbreviation}'
        customNetworkInterfaceName: 'pe-${acrName}-${regionAbbreviation}-nic'

        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.acr.dnsZone
            }
          ]
        }
      }
    ]
    quarantinePolicyStatus: 'disabled'
    softDeletePolicyStatus: 'disabled'
    softDeletePolicyDays: 7
    trustPolicyStatus: 'enabled'
    
  }
}

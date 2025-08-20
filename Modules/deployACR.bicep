// This module deploys an Azure Container Registry (ACR) with private endpoint connectivity

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param PEsubNetId string

// Variables for naming conventions
var deploymentName = 'DeployACR-${projectName}-${regionAbbreviation}'

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Get the Private DNS Zone mapping
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

// Azure Container Registry deployment
module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: deploymentName
  params: {
    name: naming.outputs.containerRegistry
    acrAdminUserEnabled: false
    acrSku: 'Premium'
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    exportPolicyStatus: 'enabled'
    location: location.region
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        subnetResourceId: PEsubNetId
        name: naming.outputs.pe_acr
        customNetworkInterfaceName: naming.outputs.pe_acr_nic

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

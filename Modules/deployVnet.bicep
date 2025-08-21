// This modules deploys a full Vnet with the dependencies

//Importing necessary types
import { regionType, getLocation, regionDefinitionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param vNetDescription string
param vNetAddressSpace string
param projectName string

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

var vNetName = naming.outputs.vNet

var vNetFullName = 'vnet-${vNetDescription}-${regionAbbreviation}'

//Deploy Vnet
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.0' = {
  params: {
    addressPrefixes: [
      vNetAddressSpace
    ]
    name: vNetFullName
    //name: naming.outputs.vNet
    location: location.region
    dnsServers: location.dnsServers
    // Configure hub-and-spoke peering
    peerings: [
      {
        name: 'peering-${vNetName}-fortigate_int-${regionAbbreviation}'
        remotePeeringName: 'peering-fortigate_int-${regionAbbreviation}-${vNetName}' 
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true       
        remoteVirtualNetworkResourceId: location.firewall.internal
        useRemoteGateways: false
      }
    ]
  }
}
output vNetName string = vNetName
output subnetID array = virtualNetwork.outputs.subnetResourceIds

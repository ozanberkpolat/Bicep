param SpokeVnetAddressSpace array
param location string
param DNServers array
param HubVirtualNetworkResourceId string
param environment string

var SpokeVnetName = 'vnet-${environment}-gwc'

module SpokeVNet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  params: {
    name: SpokeVnetName
    addressPrefixes: SpokeVnetAddressSpace
    location: location
    dnsServers: DNServers
    peerings: [
      {
        name: 'peering-from-${SpokeVnetName}-to-vnet-hub-gwc'
        remotePeeringName: 'peering-from-vnet-hub-gwc-to-${SpokeVnetName}' 
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true       
        remoteVirtualNetworkResourceId: HubVirtualNetworkResourceId
        useRemoteGateways: false
      }
    ]
  }
}
output Name string = SpokeVNet.outputs.name

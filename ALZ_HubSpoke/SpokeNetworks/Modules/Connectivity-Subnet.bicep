param subnetPrefix string
param vnetName string
param location string
param delegation string
param disablePrivateEndpointNetworkPolicies bool = false
param environment string
param subnetUsecase string

var subnetName = 'snet-${environment}-${subnetUsecase}'

module nsg 'br/public:avm/res/network/network-security-group:0.5.1' = {
  params: {
    name: 'nsg-${subnetName}'
    location: location
  }
}

module RouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  params: {
    name: 'rt-${subnetName}'
    location: location
    routes:[
      {
        name: 'route-to-hub'
        properties:{
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '192.168.1.200'
        }
      }
    ]
  }
}

module subnet 'br/public:avm/res/network/virtual-network/subnet:0.1.3' = {
  params: {
    name: subnetName
    virtualNetworkName: vnetName
    addressPrefix: subnetPrefix
    networkSecurityGroupResourceId: nsg.outputs.resourceId
    delegation: delegation
    privateEndpointNetworkPolicies: disablePrivateEndpointNetworkPolicies
      ? 'Disabled'
      : 'Enabled'
  }
}


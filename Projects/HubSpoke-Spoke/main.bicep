// Example: add a spoke VNet to an existing hub. Creates the spoke VNet, its route table (default route to the NVA),
// the spoke-to-hub peering, the hub-to-spoke peering and the route to the spoke in the hub route tables.
// Scope: resource group of the spoke.
//   az deployment group create -g <spoke-rg> -f main.bicep -p main.bicepparam
// Needs Network Contributor on the spoke RG and on the hub RG (peering and routes are written there too).
targetScope = 'resourceGroup'

param spokeVnetName string
param location string = resourceGroup().location
param spokeAddressPrefixes array
param spokeSubnets array
param blackholePrefixes array = []

param hubSubscriptionId string = subscription().subscriptionId
param hubResourceGroupName string
param hubVnetName string
@description('Hub route tables that need a route back to the spoke.')
param hubRouteTableNames array = []
param nvaIpAddress string
param extraRoutePrefixes array = []
param useRemoteGateways bool = false

resource hubVnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: hubVnetName
}

module spoke '../../Modules/deploySpokeVnet.bicep' = {
  name: 'spoke-${spokeVnetName}'
  params: {
    vNetName: spokeVnetName
    location: location
    addressPrefixes: spokeAddressPrefixes
    subnets: spokeSubnets
    hubVnetResourceId: hubVnet.id
    nvaIpAddress: nvaIpAddress
    extraRoutePrefixes: extraRoutePrefixes
    blackholePrefixes: blackholePrefixes
    useRemoteGateways: useRemoteGateways
  }
}

module hubSide '../../Modules/deployHubSpokeLink.bicep' = {
  name: 'hub-link-${spokeVnetName}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    hubVnetName: hubVnetName
    spokeVnetResourceId: spoke.outputs.vNetResourceId
    spokeAddressPrefixes: spokeAddressPrefixes
    hubRouteTableNames: hubRouteTableNames
    nvaIpAddress: nvaIpAddress
    allowGatewayTransit: useRemoteGateways
  }
}

output spokeVnetId string = spoke.outputs.vNetResourceId

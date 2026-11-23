// This module deploys the HUB side of a hub and spoke link: the hub-to-spoke peering and a route to the spoke range
// in each hub route table that must reach it through the NVA. Scope: resource group of the hub VNet.
// Pair it with deploySpokeVnet (spoke side). If the hub route tables live in another resource group, deploy this
// module once per group with an empty hubVnetName for the routes-only call (peering skipped).
//
// Lessons kept from the source deployment:
//  - Hub subnets that have their own route table (gateway, identity, management) each need a route for the new
//    spoke prefix to the NVA, otherwise replies take the system route (peering) around the firewall and break
//    asymmetrically. Pass every such route table in hubRouteTableNames.
//  - allowGatewayTransit true on the hub side lets the spoke use the hub gateway (spoke useRemoteGateways true).
//  - allowForwardedTraffic true is required for traffic that the NVA forwards.
// UNTESTED: not deployed against a live subscription; run `az deployment group what-if` first.

@description('Existing hub VNet name. Empty skips the peering.')
param hubVnetName string = ''

@description('Resource ID of the spoke VNet.')
param spokeVnetResourceId string

@description('Spoke address prefixes to route to the NVA.')
param spokeAddressPrefixes array

param allowGatewayTransit bool = true

@description('Existing hub route tables (same resource group) that get a route to the spoke.')
param hubRouteTableNames array = []

param nvaIpAddress string

var spokeName = last(split(spokeVnetResourceId, '/'))

resource hubVnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = if (!empty(hubVnetName)) {
  name: hubVnetName
}

resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-05-01' = if (!empty(hubVnetName)) {
  parent: hubVnet
  name: 'peer-${hubVnetName}-to-${spokeName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetResourceId
    }
  }
}

// One route per (route table, spoke prefix)
var routePairs = flatten(map(hubRouteTableNames, rt => map(range(0, length(spokeAddressPrefixes)), i => {
  routeTable: rt
  index: i
})))

resource hubRouteTables 'Microsoft.Network/routeTables@2025-05-01' existing = [for rt in hubRouteTableNames: {
  name: rt
}]

resource spokeRoutes 'Microsoft.Network/routeTables/routes@2025-05-01' = [
  for pair in routePairs: {
    name: '${pair.routeTable}/route-${spokeName}-${pair.index + 1}'
    properties: {
      addressPrefix: spokeAddressPrefixes[pair.index]
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nvaIpAddress
    }
    dependsOn: [
      hubRouteTables
    ]
  }
]

// This module deploys a spoke VNet with subnets, a route table that forces traffic through an NVA (firewall), and
// the spoke-side peering to the hub. Scope: resource group of the spoke. The hub side is deployed by
// deployHubSpokeLink (scope: hub resource group): a peering exists only when BOTH sides are created.
//
// Lessons kept from the source deployment:
//  - Spoke route table: 0.0.0.0/0 to the NVA. disableBgpRoutePropagation true stops on-premises routes learned from
//    a hub gateway from overriding the UDR.
//  - blackholePrefixes sends a prefix to nextHopType 'None' (dropped). Used to make a test/non-prod spoke unable to
//    reach a production range even if the NVA would allow it.
//  - allowForwardedTraffic must be true on both peerings, or traffic returning from the NVA in the hub is dropped.
//  - useRemoteGateways true only works when the hub VNet has a gateway and its side has allowGatewayTransit true;
//    otherwise the peering fails. Default false.
//  - NSGs are NOT created here: attach them per subnet through subnets[].networkSecurityGroupId.
// UNTESTED: not deployed against a live subscription; run `az deployment group what-if` first.

param vNetName string
param location string = resourceGroup().location

@description('Address space of the spoke, for example [\'10.20.0.0/24\'].')
param addressPrefixes array

@description('Each: { name, addressPrefix, networkSecurityGroupId? (full resource ID), privateEndpointNetworkPolicies? }. All subnets get the route table.')
param subnets array

param dnsServers array = []

@description('Resource ID of the hub VNet.')
param hubVnetResourceId string

@description('IP of the NVA (firewall internal interface) in the hub.')
param nvaIpAddress string

@description('Extra prefixes also sent to the NVA.')
param extraRoutePrefixes array = []

@description('Prefixes dropped (next hop None).')
param blackholePrefixes array = []

param routeTableName string = 'rt-${vNetName}'

param useRemoteGateways bool = false

param tags object = {}

var defaultRoute = [
  {
    name: 'rt-default-nva'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nvaIpAddress
    }
  }
]

var extraRoutes = [
  for (prefix, i) in extraRoutePrefixes: {
    name: 'route-nva-${i + 1}'
    properties: {
      addressPrefix: prefix
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nvaIpAddress
    }
  }
]

var blackholeRoutes = [
  for (prefix, i) in blackholePrefixes: {
    name: 'route-blackhole-${i + 1}'
    properties: {
      addressPrefix: prefix
      nextHopType: 'None'
    }
  }
]

resource routeTable 'Microsoft.Network/routeTables@2025-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: concat(defaultRoute, extraRoutes, blackholeRoutes)
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' = {
  name: vNetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: empty(dnsServers) ? null : { dnsServers: dnsServers }
    subnets: [
      for s in subnets: {
        name: s.name
        properties: {
          addressPrefix: s.addressPrefix
          routeTable: {
            id: routeTable.id
          }
          networkSecurityGroup: contains(s, 'networkSecurityGroupId') ? { id: s.networkSecurityGroupId } : null
          privateEndpointNetworkPolicies: s.?privateEndpointNetworkPolicies ?? 'Enabled'
        }
      }
    ]
  }
}

resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-05-01' = {
  parent: vnet
  name: 'peer-${vNetName}-to-${last(split(hubVnetResourceId, '/'))}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: hubVnetResourceId
    }
  }
}

output vNetResourceId string = vnet.id
output vNetName string = vnet.name
output routeTableResourceId string = routeTable.id
output addressPrefixes array = addressPrefixes

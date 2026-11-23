// This module deploys a dedicated AVD session host subnet in an EXISTING VNet, with a standard AVD NSG and an
// optional route table that sends traffic to a network virtual appliance (NVA / firewall).
// Scope: the resource group of the VNet.
//
// Lessons kept from the source deployment:
//  - The NSG allows RDP Shortpath over UDP 3390 inside the VNet and the Azure Load Balancer probe, then denies the
//    rest inbound. AVD session hosts only make OUTBOUND connections to the service, so no inbound internet rule is
//    needed. Outbound to the AVD service FQDNs/service tags must be allowed by the firewall behind the route table.
//  - The route table sends 0.0.0.0/0 (and any extra prefixes) to the NVA. With forced tunnelling, make sure the
//    NVA allows the AVD required URLs, otherwise session hosts register but never go Available.
//  - Existing subnets are updated in place: deploying over a subnet that already has other settings (delegations,
//    service endpoints) overwrites them, so check with what-if first.
// UNTESTED: not deployed against a live subscription; run `az deployment group what-if` first.

@description('Name of the existing VNet.')
param vNetName string

param subnetName string
param subnetAddressPrefix string

param location string = resourceGroup().location

@description('NSG name. Empty skips the NSG.')
param nsgName string = 'nsg-${subnetName}'

@description('Route table name. Created only when nextHopIpAddress is set.')
param routeTableName string = 'rt-${subnetName}'

@description('IP address of the NVA. Empty means no route table.')
param nextHopIpAddress string = ''

@description('Extra prefixes also sent to the NVA, for example the VNet or VPN ranges, to keep that traffic inspected.')
param extraRoutePrefixes array = []

param tags object = {}

var defaultRoute = [
  {
    name: 'route-default-nva'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nextHopIpAddress
    }
  }
]

var extraRoutes = [
  for (prefix, i) in extraRoutePrefixes: {
    name: 'route-extra-${i + 1}'
    properties: {
      addressPrefix: prefix
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nextHopIpAddress
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vNetName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' = if (!empty(nsgName)) {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-Shortpath-Inbound'
        properties: {
          description: 'RDP Shortpath UDP transport between AVD client and session host.'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '3390'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer-Inbound'
        properties: {
          description: 'Azure Load Balancer health probes.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          description: 'Deny all inbound traffic not explicitly allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2025-05-01' = if (!empty(nextHopIpAddress)) {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: concat(defaultRoute, extraRoutes)
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: !empty(nsgName) ? { id: nsg.id } : null
    routeTable: !empty(nextHopIpAddress) ? { id: routeTable.id } : null
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output subnetResourceId string = subnet.id

using './main.bicep'

// General Parameters
param parLocations = [
  'germanywestcentral'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the prod Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = false

// Resource Group Parameters
param parHubNetworkingResourceGroupNamePrefix = 'rg-hub-prod-gwc'
param parDnsResourceGroupNamePrefix = 'rg-dns-prod-gwc'
param parDnsPrivateResolverResourceGroupNamePrefix = 'rg-dnspr-prod-gwc'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-hub-gwc'
    location: parLocations[0]
    addressPrefixes: [
      '192.168.0.0/23'
    ]
    deployPeering: true
    dnsServers: []
    peeringSettings: [
      {
        remoteVirtualNetworkName: 'vnet-prod-gn'
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
      }
    ]
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '192.168.0.0/26'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '192.168.0.64/26'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '192.168.0.128/26'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '192.168.0.192/26'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '192.168.1.0/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '192.168.1.16/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: '192.168.1.64/26'
      }
      {
        name: 'VMSubnet'
        addressPrefix: '192.168.1.128/26'
      }
    ]
    azureFirewallSettings: {
      deployAzureFirewall: true
      azureFirewallName: 'afw-prod-gwc'
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-afw-prod-gwc'
      }
      managementIPAddressObject: {
        name: 'pip-afw-mgmt-prod-gwc'
      }
    }
    bastionHostSettings: {
      deployBastion: true
      bastionHostSettingsName: 'bas-prod-gwc'
      skuName: 'Standard'
      zones: []
    }
    vpnGatewaySettings: {
      deployVpnGateway: false
      name: 'vgw-prod-gwc'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
    }
    expressRouteGatewaySettings: {
      deployExpressRouteGateway: true
      name: 'ergw-prod-gwc'
    }
    privateDnsSettings: {
      deployPrivateDnsZones: true
      deployDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-prod-gwc'
      privateDnsZones: []
    }
    ddosProtectionPlanSettings: {
      deployDdosProtectionPlan: false
      name: 'ddos-prod-gwc'
    }
  }
]

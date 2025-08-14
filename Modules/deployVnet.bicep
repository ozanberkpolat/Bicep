// This modules deploys a full Vnet with the dependencies

//Importing necessary types
import { regionType, subnetType, getLocation, regionDefinitionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param region regionType
param vNetDescription string
param vNetAddressSpace string[]
param subnetsDefinitions subnetType[]

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(region) 

// Variables for naming conventions
var spokeVNet = 'vnet-${vNetDescription}-${region}'
var routeTablename = 'rt-${spokeVNet}'

// Deploy NSG with default inbound rules
module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.1' = [
  for subnet in subnetsDefinitions: {
    name: 'nsgDeployment-${subnet.name}-${spokeVNet}'
    params: {
      name: 'nsg-${subnet.name}'
      location: location.region
      securityRules: union(subnet.rules, [
        {
          name: 'Allow_All_InsideSubnet'
          properties: {
            priority: 4093
            direction: 'Inbound'
            access: 'Allow'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: subnet.addressPrefix
            destinationAddressPrefix: subnet.addressPrefix
          }
        }
        {
          name: 'Deny_All_FromOtherSubnetsInVnet'
          properties: {
            priority: 4094
            direction: 'Inbound'
            access: 'Deny'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefixes: vNetAddressSpace
            destinationAddressPrefix: subnet.addressPrefix
          }
        }
        {
          name: 'Allow_All_FromOnPremAndOtherVnets'
          properties: {
            priority: 4095
            direction: 'Inbound'
            access: 'Allow'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: '10.0.0.0/8'
            destinationAddressPrefix: subnet.addressPrefix
          }
        }
        {
          name: 'Deny_All_Inbound'
          properties: {
            priority: 4096
            direction: 'Inbound'
            access: 'Deny'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ])
    }
  }
]
// Deploy Route Table with Default Route
module routeTable 'br/public:avm/res/network/route-table:0.4.1' = {
  name: 'routeTableDeployment-${routeTablename}'
  params: {

    name: routeTablename
    location: location.region
    routes: [
      {
        name: 'Traffic_to_LB'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: location.nextHopIp
        }
      }
    ]
  }
}

//Deploy Vnet
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'vnetDeployment-${spokeVNet}'
  params: {
    addressPrefixes: vNetAddressSpace
    name: spokeVNet
    location: location.region
    dnsServers: location.dnsServers
    subnets: [
      for (subnet, index) in subnetsDefinitions: {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        delegation: subnet.?delegation
        networkSecurityGroupResourceId: networkSecurityGroup[index].outputs.resourceId
        routeTableResourceId: routeTable.outputs.resourceId
      }
    ]
    // Configure hub-and-spoke peering
    peerings: [
      {
        name: 'peering-${vNetDescription}-${region}-fortigate_int-${region}'
        remotePeeringName: 'peering-fortigate_int-${region}-${vNetDescription}-${region}' 
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

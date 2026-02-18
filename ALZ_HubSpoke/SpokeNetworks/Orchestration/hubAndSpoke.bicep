targetScope = 'subscription'

// Shared Parameter
param location string
// Hub VNet Parameters
param DNServers array
// Resource Group Parameters
param productionRg string
param developmentRg string
param testingRg string
param hubVnetRg string
// Spoke VNet Parameters - Production
param productionSpokeVnetAddressSpace array
param productionSubnetPrefix1 string
param productionSubnetPrefix2 string
param productionSubnetPrefix3 string
// Spoke VNet Parameters - Development
param developmentSpokeVnetAddressSpace array
param developmentSubnetPrefix1 string
param developmentSubnetPrefix2 string
param developmentSubnetPrefix3 string
// Spoke VNet Parameters - Testing
param testingSpokeVnetAddressSpace array
param testingSubnetPrefix1 string
param testingSubnetPrefix2 string
param testingSubnetPrefix3 string

// Deploy Resource Group for Hub and Spoke architecture
// module HubVnetRG 'br/public:avm/res/resources/resource-group:0.4.3' = {
//   params: {
//     name: hubVnetRg
//     location: location
//   }
// }

// Deploy Resource Groups for Spokes
module ProdVnetRG 'br/public:avm/res/resources/resource-group:0.4.3' = {
  params: {
    name: productionRg
    location: location
  }
}

module DevVnetRG 'br/public:avm/res/resources/resource-group:0.4.3' = {
  params: {
    name: developmentRg
    location: location
  }
}

module TestVnetRG 'br/public:avm/res/resources/resource-group:0.4.3' = {
  params: {
    name: testingRg
    location: location
  }
}

// Deploy Hub and Spoke architecture
// module HubVNet '../Modules/Connectivity-HubVnet.bicep' = {
//   scope: resourceGroup(hubVnetRg)
//   params: {
//     location: location
//     DNServers: DNServers
//     HubVNetAddressPrefixes: HubVNetAddressPrefixes
//   }
//   dependsOn: [
//     HubVnetRG
//   ]
// }

resource hub 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  scope: resourceGroup(hubVnetRg)
  name: 'vnet-hub-gwc'
}

// Deploy Private DNS Zones and link to Hub VNet
// module DNSZones '../Modules/Connectivity-DnsZones.bicep' = {
//   scope: resourceGroup(hubVnetRg)
//   params: {
//     HubVirtualNetworkResourceId: hub.id
//   }
//   dependsOn: [
//     HubVnetRG
//     HubVNet
//   ]
// }

// Deploy Spoke VNet and Subnets for Production, Development and Testing
module ProdSpokeVNet '../Modules/Connectivity-SpokeVnet.bicep' = {
  scope: resourceGroup(productionRg)
  params: {
    location: location
    DNServers: DNServers
    HubVirtualNetworkResourceId: hub.id
    SpokeVnetAddressSpace: productionSpokeVnetAddressSpace
    environment: 'prod'
  }
  dependsOn: [
    ProdVnetRG
  ]
}

module ProdSubnet1 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(productionRg)
  params: {
    location: location
    delegation: ''
    subnetPrefix: productionSubnetPrefix1
    vnetName: ProdSpokeVNet.outputs.Name
    environment: 'prod'
    subnetUsecase: 'privateendpoints'
  }
  dependsOn: [
    ProdVnetRG
  ]
}

module ProdSubnet2 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(productionRg)
  params: {
    location: location
    delegation: ''
    subnetPrefix: productionSubnetPrefix2
    vnetName: ProdSpokeVNet.outputs.Name
    environment: 'prod'
    subnetUsecase: 'vm'
  }
  dependsOn: [
    ProdSubnet1
  ]
}

module ProdSubnet3 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(productionRg)
  params: {
    location: location
    delegation: 'Microsoft.Web/serverFarms'
    subnetPrefix: productionSubnetPrefix3
    vnetName: ProdSpokeVNet.outputs.Name
    environment: 'prod'
    subnetUsecase: 'app'
  }
  dependsOn: [
    ProdSubnet2
  ]
}

module DevSpokeVNet '../Modules/Connectivity-SpokeVnet.bicep' = {
  scope: resourceGroup(developmentRg)
  params: {
    location: location
    DNServers: DNServers
    HubVirtualNetworkResourceId: hub.id
    SpokeVnetAddressSpace: developmentSpokeVnetAddressSpace
    environment: 'dev'
  }
  dependsOn: [
    DevVnetRG
  ]
}

module DevSubnet1 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(developmentRg)
  params: {
    location: location
    delegation: ''
    subnetPrefix: developmentSubnetPrefix1
    vnetName: DevSpokeVNet.outputs.Name
    environment: 'dev'
    subnetUsecase: 'privateendpoints'
  }
  dependsOn: [
    DevVnetRG
  ]
}

module DevSubnet2 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(developmentRg)
  params: {
    location: location
    delegation: ''
    subnetPrefix: developmentSubnetPrefix2
    vnetName: DevSpokeVNet.outputs.Name
    environment: 'dev'
    subnetUsecase: 'vm'
  }
  dependsOn: [
    DevSubnet1
  ]
}

module DevSubnet3 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(developmentRg)
  params: {
    location: location
    delegation: 'Microsoft.Web/serverFarms'
    subnetPrefix: developmentSubnetPrefix3
    vnetName: DevSpokeVNet.outputs.Name
    environment: 'dev'
    subnetUsecase: 'app'
  }
  dependsOn: [
    DevSubnet2
  ]
}

module TestSpokeVNet '../Modules/Connectivity-SpokeVnet.bicep' = {
  scope: resourceGroup(testingRg)
  params: {
    location: location
    DNServers: DNServers
    HubVirtualNetworkResourceId: hub.id
    SpokeVnetAddressSpace: testingSpokeVnetAddressSpace
    environment: 'test'
  }
  dependsOn: [
    TestVnetRG
  ]
}

module TestSubnet1 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(testingRg)
  params: {
    location: location
    delegation: ''
    subnetPrefix: testingSubnetPrefix1
    vnetName: TestSpokeVNet.outputs.Name
    environment: 'test'
    subnetUsecase: 'privateendpoints'
  }
  dependsOn: [
    TestVnetRG
  ]
}

module TestSubnet2 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(testingRg)
  params: {
    location: location
    delegation: ''
    subnetPrefix: testingSubnetPrefix2
    vnetName: TestSpokeVNet.outputs.Name
    environment: 'test'
    subnetUsecase: 'vm'
  }
  dependsOn: [
    TestSubnet1
  ]
}

module TestSubnet3 '../Modules/Connectivity-Subnet.bicep' = {
  scope: resourceGroup(testingRg)
  params: {
    location: location
    delegation: 'Microsoft.Web/serverFarms'
    subnetPrefix: testingSubnetPrefix3
    vnetName: TestSpokeVNet.outputs.Name
    environment: 'test'
    subnetUsecase: 'app'
  }
  dependsOn: [
    TestSubnet2
  ]
}

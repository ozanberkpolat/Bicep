using './hubAndSpoke.bicep'

// Shared Parameters
param location = 'germanywestcentral'

// Resource Groups
param hubVnetRg = 'rg-hub-prod-gwc'
param productionRg = 'rg-vnet-prod-gwc'
param developmentRg = 'rg-vnet-dev-gwc'
param testingRg = 'rg-vnet-test-gwc'

// Hub VNet
// param HubVNetAddressPrefixes = ['192.168.0.0/23']
param DNServers = ['192.168.0.132']

// Spoke 1 - Production
param productionSpokeVnetAddressSpace = ['192.168.10.0/24']
param productionSubnetPrefix1 = '192.168.10.0/26'
param productionSubnetPrefix2 = '192.168.10.64/27'
param productionSubnetPrefix3 = '192.168.10.96/27'

// Spoke 2 - Development
param developmentSpokeVnetAddressSpace = ['192.168.20.0/24']
param developmentSubnetPrefix1 = '192.168.20.0/26'
param developmentSubnetPrefix2 = '192.168.20.64/27'
param developmentSubnetPrefix3 = '192.168.20.96/27'

// Spoke 3 - Testing
param testingSpokeVnetAddressSpace = ['192.168.30.0/24']
param testingSubnetPrefix1 = '192.168.30.0/26'
param testingSubnetPrefix2 = '192.168.30.64/27'
param testingSubnetPrefix3 = '192.168.30.96/27'

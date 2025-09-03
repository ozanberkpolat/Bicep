targetScope = 'subscription'
param Existing_Vnet_name string
param Existing_subNet_name string
param projectName string
param regionAbbreviation string
param vNetRG string
param deploymentRG string


resource Existing_vNet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  scope: resourceGroup(vNetRG)
  name: Existing_Vnet_name
}

resource Existing_subNet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: Existing_subNet_name
  parent:Existing_vNet
}

module CDB '../../../modules/deployCosmosDB.bicep' = {
  scope: resourceGroup(deploymentRG)
  params: {
    CosmosDBType: 'SQL'
    peSubnetResourceId: Existing_subNet.id
    projectName: projectName
    regionAbbreviation: regionAbbreviation
  }
}

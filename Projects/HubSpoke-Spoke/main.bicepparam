using './main.bicep'

param spokeVnetName = 'vnet-contoso-app-weu'
param spokeAddressPrefixes = [ '10.20.0.0/26' ]
param spokeSubnets = [
  { name: 'snet-app', addressPrefix: '10.20.0.0/28' }
]

// Optional: drop traffic to a protected range even if the firewall would allow it
param blackholePrefixes = [ '10.10.5.0/28' ]

param hubResourceGroupName = 'rg-contoso-hub-weu'
param hubVnetName = 'vnet-contoso-hub-weu'
param hubRouteTableNames = [ 'rt-contoso-hub-gateway', 'rt-contoso-hub-management' ]
param nvaIpAddress = '10.10.0.4'

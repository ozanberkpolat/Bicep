using './main.bicep'

param hostPoolName = 'hp-contoso-desktop-weu'
param appGroupName = 'ag-contoso-desktop-weu'
param workspaceName = 'ws-contoso-weu'
param location = 'westeurope'
param appGroupType = 'Desktop'

// Entra group object ID that may sign in (placeholder: replace with a real group)
param userObjectIds = [
  '00000000-0000-0000-0000-000000000000'
]

// Dedicated subnet in an existing VNet; set vNetResourceGroup = '' to skip and pass existingSubnetResourceId
param vNetResourceGroup = 'rg-contoso-network-weu'
param vNetName = 'vnet-contoso-weu'
param subnetName = 'snet-avd'
param subnetAddressPrefix = '10.20.0.0/28'
param nextHopIpAddress = '10.20.1.4'

param sessionHostCount = 0
param adminUsername = readEnvironmentVariable('AVD_ADMIN_USER', 'avdadmin')
param adminPassword = readEnvironmentVariable('AVD_ADMIN_PASSWORD', '')

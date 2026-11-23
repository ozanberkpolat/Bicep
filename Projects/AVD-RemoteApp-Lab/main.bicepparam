using './main.bicep'

param hostPoolName = 'hp-contoso-app-weu'
param appGroupName = 'ag-contoso-app-weu'
param workspaceName = 'ws-contoso-app-weu'

// Entra group object ID (placeholder: replace with a real group)
param userObjectIds = [
  '00000000-0000-0000-0000-000000000000'
]

param sessionHostCount = 1
param adminUsername = readEnvironmentVariable('AVD_ADMIN_USER', 'avdadmin')
param adminPassword = readEnvironmentVariable('AVD_ADMIN_PASSWORD')

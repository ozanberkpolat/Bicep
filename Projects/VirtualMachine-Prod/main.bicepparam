using './main.bicep'

param VMSize = 'large'
param OS = 'Windows Server 2019'
param regionAbbreviation = 'usc'
param VMName
param vNetRG
param deploymentRG
param adminPassword = readEnvironmentVariable('VM_LOCAL_ADMIN_PASSWORD')

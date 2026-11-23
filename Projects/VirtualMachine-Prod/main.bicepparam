using './main.bicep'

param VMSize = 'large'
param OS = 'Windows Server 2019'
param regionAbbreviation = 'usc'
param VMName = 'vm-contoso-01'
param vNetRG = 'rg-contoso-network-usc'
param deploymentRG = 'rg-contoso-compute-usc'
param adminUsername = readEnvironmentVariable('VM_LOCAL_ADMIN_USER')
param adminPassword = readEnvironmentVariable('VM_LOCAL_ADMIN_PASSWORD')

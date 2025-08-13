using './main.bicep'

param SizeOfVM = '' // Example: 'small', 'medium', 'large'
param TypeofOS = '' // Example: 'Windows Server 2022', 'Linux' or 'Windows Server 2019'
param VMName = ''
param regionAbbreviation = ''
param subnetName = ''
param vNetRG = ''
param vNetName = ''

using './main.bicep'

param peSubnetName = ''
param projectName = ''
param regionAbbreviation = ''
param subscriptionId = ''
param vNetName = ''
param vNetRG = ''
param SAKind = 'BlobStorage' // Example: 'StorageV2', 'BlobStorage', 'FileStorage'
param serviceEndpoints = ['blob'] // Example: ['blob', 'file', 'table'] - MUST be in array format
// Only the blob endpoint is usable for BlobStorage accounts


param peSubnetName string
param projectName string
param regionAbbreviation regionType
param subscriptionId string
param vNetName string
param vNetRG string
param serviceEndpoints array 
param SAKind storageAccountKind

import { storageAccountKind } from '../../modules/.shared/commonTypes.bicep'
import { regionType } from '../../modules/.shared/commonTypes.bicep'

module DataLake_SA '../../modules/deployStorageAccount.bicep' = {
  params: {
    peSubnetName: peSubnetName
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionId: subscriptionId
    vNetName: vNetName
    vNetRG: vNetRG
    serviceEndpoints: serviceEndpoints
    SAKind: SAKind
  }
}

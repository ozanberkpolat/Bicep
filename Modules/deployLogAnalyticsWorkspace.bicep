// This module deploys Application Insights

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType
param storageAccountName string
param storageAccountId string 


// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

module Log_Analytics_Workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  params: {
    name: naming.outputs.logAnalyticsWorkspace
    location: location
    dailyQuotaGb: -1
    skuName:'PerGB2018'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    managedIdentities: {
      systemAssigned: true
    }
    dataRetention: 30
    
    linkedStorageAccounts: [
      {
        name: 'link-${storageAccountName}'
        storageAccountIds: [
          storageAccountId
        ]
      }
    ]
  }
}

output Log_Workspace_ID string = Log_Analytics_Workspace.outputs.logAnalyticsWorkspaceId

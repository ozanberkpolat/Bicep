// This module deploys Application Insights

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType
param LogAnalyticsWorkspaceId string
param StorageAccountResourceId string 


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

module App_Insights 'br/public:avm/res/insights/component:0.6.0' = {
  params: {
    name: naming.outputs.AppInsights
    location: location
    workspaceResourceId: LogAnalyticsWorkspaceId
    applicationType: 'web'
    linkedStorageAccountResourceId: StorageAccountResourceId
    retentionInDays: 90
  }
}

output Connection_String string = App_Insights.outputs.connectionString
output InstrumentationKey string = App_Insights.outputs.instrumentationKey
output Resource_ID string = App_Insights.outputs.resourceId

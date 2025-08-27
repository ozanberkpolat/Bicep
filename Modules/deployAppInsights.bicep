// This module deploys Application Insights

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType
param LogAnalyticsWorkspaceResourceId string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

var Name = naming.outputs.Resources.AppInsights

module App_Insights 'br/public:avm/res/insights/component:0.6.0' = {
  params: {
    name: Name
    location: location.region
    workspaceResourceId: LogAnalyticsWorkspaceResourceId
    applicationType: 'web'
    retentionInDays: 90
  }
}

output Connection_String string = App_Insights.outputs.connectionString
output InstrumentationKey string = App_Insights.outputs.instrumentationKey
output Resource_ID string = App_Insights.outputs.resourceId

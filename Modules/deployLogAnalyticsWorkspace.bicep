// This module deploys Application Insights

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType

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

var Name = naming.outputs.Resources.logAnalyticsWorkspace

module Log_Analytics_Workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  params: {
    name: Name
    location: location.region
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
  }
}

output Workspace_ID string = Log_Analytics_Workspace.outputs.logAnalyticsWorkspaceId
output resource_ID string = Log_Analytics_Workspace.outputs.resourceId
output Name string = Log_Analytics_Workspace.outputs.name

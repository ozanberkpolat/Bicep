// This module deploys Log Analytics Workspace and Application Insights

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType

// Variables for naming conventions
var LogName = 'log-${projectName}-${regionAbbreviation}'
var AppInsightsName = 'appi-${projectName}-${regionAbbreviation}'

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Deploy Log Analytics Workspace
resource Log 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: LogName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Deploy Application Insights
resource AppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: AppInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: Log.id
  }
}
output logAnalyticsWorkspaceId string = Log.id
output appInsightsId string = AppInsights.id

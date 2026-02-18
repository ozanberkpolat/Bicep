using 'main.bicep'

// General Parameters
param parLocations = [
  'germanywestcentral'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the prod Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = true

// Resource Group Parameters
param parMgmtLoggingResourceGroup = 'rg-logging-prod-gwc'

// Automation Account Parameters
param parAutomationAccountName = 'aa-prod-gwc'
param parAutomationAccountLocation = parLocations[0]
param parDeployAutomationAccount = false
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'law-prod-gwc'
param parLogAnalyticsWorkspaceLocation = parLocations[0]
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceDailyQuotaGb = null
param parLogAnalyticsWorkspaceReplication = null
param parLogAnalyticsWorkspaceFeatures = null
param parLogAnalyticsWorkspaceDataExports = null
param parLogAnalyticsWorkspaceDataSources = null
param parLogAnalyticsWorkspaceSolutions = [
  'ChangeTracking'
]

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'mi-prod-gwc'
param parDataCollectionRuleVMInsightsName = 'dcr-vmi-prod-gwc'
param parDataCollectionRuleChangeTrackingName = 'dcr-ct-prod-gwc'
param parDataCollectionRuleMDFCSQLName = 'dcr-mdfcsql-prod-gwc'

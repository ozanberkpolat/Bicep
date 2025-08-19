@description('Log Analytics workspace name')
param logAnalyticsName string

@secure()
output primarySharedKey string = listKeys(
  resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsName),
  '2020-08-01'
).primarySharedKey

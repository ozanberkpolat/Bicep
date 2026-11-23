// This module deploys a data collection rule (DCR) for VM Insights and optionally associates it with VMs.
// Scope: resource group. The DCR sends the VM Insights performance stream (Microsoft-InsightsMetrics, counter
// \VmInsights\DetailedMetrics) to a Log Analytics workspace; the Insights > Performance charts read that table.
//
// Lessons kept from the source:
//  - A DCR alone collects nothing. The Azure Monitor agent (AMA) must be on the VM AND the VM must be associated with
//    the DCR. deployVM installs AMA and creates associations through its dataCollectionRuleResourceIds parameter; use
//    vmNamesToAssociate here for VMs that already exist (the AMA extension must then be installed separately, for
//    example by the 'Configure Windows/Linux machines to run Azure Monitor Agent' policies or deployVM).
//  - 'Map' (dependency map) needs the extra DependencyAgent extension on every VM and the ServiceMap stream; it is
//    off by default (enableMap) because Microsoft is retiring the Dependency agent path.
//  - Heartbeat stays empty without agent AND DCR, so an empty Heartbeat table means the association is missing.
//  - The DCR must be in the same region as the workspace (and, for the association, a region AMA supports).
//  - Every ingested row is billed in Log Analytics: sampling 60 s is the portal default, raise it to save cost.
// UNTESTED: built from the Microsoft Learn DCR schema, not deployed. Verify with `az deployment group what-if`,
// then query: InsightsMetrics | where Origin == "vm.azm.ms" | take 10.

param dcrName string

param location string = resourceGroup().location

@description('Log Analytics workspace resource ID the data goes to.')
param logAnalyticsWorkspaceId string

@description('Counter sampling interval in seconds.')
@minValue(10)
@maxValue(1800)
param samplingFrequencyInSeconds int = 60

@description('Add the dependency map data source (needs the DependencyAgent extension on the VMs).')
param enableMap bool = false

@description('Names of existing VMs in this resource group to associate with the DCR.')
param vmNamesToAssociate array = []

param tags object = {}

var destinationName = 'vmi-logs-destination'

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  tags: tags
  properties: {
    description: 'VM Insights performance data'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
          samplingFrequencyInSeconds: samplingFrequencyInSeconds
        }
      ]
      extensions: enableMap
        ? [
            {
              name: 'DependencyAgentDataSource'
              extensionName: 'DependencyAgent'
              streams: [
                'Microsoft-ServiceMap'
              ]
              extensionSettings: {}
            }
          ]
        : []
    }
    destinations: {
      logAnalytics: [
        {
          name: destinationName
          workspaceResourceId: logAnalyticsWorkspaceId
        }
      ]
    }
    dataFlows: concat(
      [
        {
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          destinations: [
            destinationName
          ]
        }
      ],
      enableMap
        ? [
            {
              streams: [
                'Microsoft-ServiceMap'
              ]
              destinations: [
                destinationName
              ]
            }
          ]
        : []
    )
  }
}

resource vms 'Microsoft.Compute/virtualMachines@2025-04-01' existing = [for name in vmNamesToAssociate: {
  name: name
}]

resource association 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = [
  for (name, i) in vmNamesToAssociate: {
    name: '${dcrName}-association'
    scope: vms[i]
    properties: {
      dataCollectionRuleId: dcr.id
      description: 'VM Insights association'
    }
  }
]

output dataCollectionRuleId string = dcr.id

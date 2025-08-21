// This module deploys Managed DevOps Pool

// Importing necessary types
import { regionType, OSType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param regionAbbreviation regionType
param NumberOfAgents int
param OrganizationName string
param AZDO_ProjectName string
param VMSize string
param OS OSType
param ProjectID string

// Importing shared resources and configurations
var skuMap = loadJsonContent('.shared/vmSizes.json')
var selectedSku = skuMap[VMSize]
var osMAP = loadJsonContent('.shared/MDP_OS.json')
var selectedOS = osMAP[OS]

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

// Deploy Managed DevOps Pool
module Create_MDP 'br/public:avm/res/dev-ops-infrastructure/pool:0.7.0' = {
  params: {
    name: naming.outputs.ManagedDevOpsPool
    agentProfile: {
      maxAgentLifetime: '7.00:00:00'
      gracePeriodTimeSpan: '7.00:00:00'
      kind: 'Stateful'
    }
    concurrency: NumberOfAgents
    location: location.region
    fabricProfileSkuName: selectedSku
    devCenterProjectResourceId: ProjectID
    osProfile: {
      logonType: 'Service'
      secretsManagementSettings: {
        observedCertificates: []
        keyExportable: false
      }
    }
    images: [
        {
          aliases: [
            selectedOS.alias
          ]
          buffer: '*'
          wellKnownImageName: selectedOS.wellKnownImageName
        }
      ]
    storageProfile:{
      dataDisks:[
        {
          diskSizeGiB: 50
          storageAccountType:'Standard_LRS'
        }
      ]
    osDiskStorageAccountType:'Standard'
    }

    organizationProfile: {
      organizations: [
        {
          url: 'https://dev.azure.com/${OrganizationName}'
          projects: [
            AZDO_ProjectName
          ]
          parallelism: NumberOfAgents
          openAccess: false
        }
      ]
      permissionProfile: {
        kind: 'Inherit'
      }
      kind: 'AzureDevOps'
    }
  }
}

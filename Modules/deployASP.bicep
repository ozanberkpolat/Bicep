// This module deploys an App Service Plan (ASP) 

// Importing necessary types
import { OSType, regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param sku string
param osType OSType
param regionAbbreviation regionType

// Variables for naming conventions
var appServicePlanName = 'plan-${projectName}-${regionAbbreviation}'

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// SKU Mapping Variable
var skuMap = {
  P1V3: {
    tier: 'PremiumV3'
    size: 'P1V3'
    family: 'PV3'
    kind: 'app'
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
  }
}

var skuConfig = skuMap[sku]


// ASP Deployment
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuConfig.size
    tier: skuConfig.tier
    family: skuConfig.family
  }
  kind: skuConfig.kind
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: skuConfig.elasticScaleEnabled
    maximumElasticWorkerCount: skuConfig.maximumElasticWorkerCount
    isSpot: false
    reserved: osType == 'Linux'
    isXenon: false
    hyperV: false
    zoneRedundant: false
  }
}

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name

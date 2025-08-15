// This module deploys an App Service Plan (ASP) 

// Importing necessary types
import { OSType, regionType, ASP_SKU } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param projectName string
param sku ASP_SKU
param osType OSType
param regionAbbreviation regionType

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// SKU Mapping Variable
var skuMap = {
  P1V3: {
    tier: 'PremiumV3'
    name: 'P1v3'
    size: 'P1V3'
    family: 'PV3'
    kind: 'app'
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
  }
}

var skuConfig = skuMap[sku]

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.5.0' = {
  params: {
    name: naming.outputs.appServicePlanName
    location: location
    skuName: skuConfig.name
    kind: skuConfig.kind
    reserved: osType == 'Linux' 
    zoneRedundant: false
    perSiteScaling: false
    elasticScaleEnabled: skuConfig.elasticScaleEnabled
    maximumElasticWorkerCount: skuConfig.maximumElasticWorkerCount
  }
}

output appServicePlanId string = appServicePlan.outputs.resourceId
output appServicePlanName string = appServicePlan.outputs.name

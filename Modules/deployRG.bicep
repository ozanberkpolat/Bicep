// Target scope must be Subscription in order to create a Resoure Group
targetScope = 'subscription'

// This module deploys a Resource Group

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param subscriptionId string
param RGName string
param regionAbbreviation regionType
param Owner string
param CostCenter string

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

// Deployment Name variable
var deploymentName = 'DeployRG-${RGName}-${regionAbbreviation}'

// Deploy Resource Group
module RG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: deploymentName
  params: {
    name: RGName
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location.region
  }  
}

output name string = RG.outputs.name
output id string = RG.outputs.resourceId

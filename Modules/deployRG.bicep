// Target scope must be Subscription in order to create a Resoure Group
targetScope = 'subscription'

// This module deploys a Resource Group

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param subscriptionId string
param RGName string
param regionAbbreviation regionType
param Owner string
param CostCenter string

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region

// Deploy Resource Group
module RG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: RGName
  params: {
    name: RGName
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location
  }  
}

output name string = RG.outputs.name
output id string = RG.outputs.resourceId

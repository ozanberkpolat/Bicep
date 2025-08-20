// This module deploys Data Bricks Workspace and it's dependent resources such as Private and Public subnets and a managed RG

// Importing necessary types
import { regionType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param PrivateSubnetName string 
param PublicSubnetName string 
param PrivateSubnetAddressSpace string
param PublicSubnetAddressSpace string 
param subscriptionId string 
param projectName string
param VNETRG string
param Owner string
param CostCenter string
param dataResourceGroup string
param PEsubNetId string
param RouteTableId string
param vNetName string
param vNetId string

// Importing shared resources and configurations
var PrivateDNSZones = json(loadTextContent('.shared/privatednszones.json'))
var PEServices = loadJsonContent('.shared/pe_services.json')

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation) 

// Deployment Name variable
var deploymentName = 'DeployDBW-${projectName}-${regionAbbreviation}'


// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

// Create managed resource group
module Create_DataRG 'br/public:avm/res/resources/resource-group:0.4.1' = {
  scope: subscription(subscriptionId)
  name: deploymentName
  params: {
    name: dataResourceGroup
    tags: {
      Owner: Owner
      CostCenter: CostCenter
    }
    location: location.region
  }  
}

// Create an empty NSG for DBW
module Create_NSG 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: deploymentName
  scope: resourceGroup(dataResourceGroup)
  params: {
    name: 'nsg-${projectName}-swn'
    location: location.region
  }
  dependsOn: [
    Create_DataRG
  ]
}

// Create Private subnet for DBW
module Create_DWHPrivateSubnet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  scope: resourceGroup(VNETRG)
  name: deploymentName
  params: {
    name: PrivateSubnetName
    virtualNetworkName: vNetName
    addressPrefix: PrivateSubnetAddressSpace
    routeTableResourceId: RouteTableId
    delegation: 'Microsoft.Databricks/workspaces'
    networkSecurityGroupResourceId: Create_NSG.outputs.resourceId
  }
}

// Create Public subnet for DBW
module Create_DWHPublicSubnet 'br/public:avm/res/network/virtual-network/subnet:0.1.2' = {
  scope: resourceGroup(VNETRG)
  name: deploymentName
  params: {
    name: PublicSubnetName
    virtualNetworkName: vNetName
    addressPrefix: PublicSubnetAddressSpace
    routeTableResourceId: RouteTableId
    delegation: 'Microsoft.Databricks/workspaces'
    networkSecurityGroupResourceId: Create_NSG.outputs.resourceId
  }
  dependsOn: [
    Create_DWHPrivateSubnet
  ]
}

// Create Data Bricks Workspace
module Create_DBW 'br/public:avm/res/databricks/workspace:0.11.2' = {
  scope: resourceGroup(dataResourceGroup)
  name: deploymentName
  params: {
    name: naming.outputs.databricksWorkspace
    location: location.region
    customPrivateSubnetName: PrivateSubnetName
    customPublicSubnetName: PublicSubnetName
    publicNetworkAccess: 'Disabled'
    skuName: 'premium'
    customVirtualNetworkResourceId: vNetId
    disablePublicIp: true
    requiredNsgRules: 'NoAzureDatabricksRules'
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.databricks.dnsZone
            }
          ]
        }
        service: PEServices.databricks_ui_api.service
        subnetResourceId: PEsubNetId
        name: naming.outputs.pe_dbw_api
      }
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: PrivateDNSZones.databricks.dnsZone
            }
          ]
        }
        service: PEServices.databricks_browser_authentication.service
        subnetResourceId: PEsubNetId
        name: naming.outputs.pe_dbw_auth
      }
    ]
  }
  dependsOn: [
    Create_DataRG
    Create_DWHPrivateSubnet
    Create_DWHPublicSubnet
  ]
}

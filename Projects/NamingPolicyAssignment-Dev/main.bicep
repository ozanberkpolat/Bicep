targetScope = 'managementGroup'

param policyName string
param displayName string
param description string
param category string
param regionAbbreviation string
param definitionManagementGroup string
param assignmentManagementGroup string


var Def_MGID = '/providers/Microsoft.Management/managementGroups/${definitionManagementGroup}'
var Assign_MGID = '/providers/Microsoft.Management/managementGroups/${assignmentManagementGroup}'
var locations = loadJsonContent('../../modules/.shared/locations.json')
var location = locations[regionAbbreviation].region
var policyRuleFile object = json(loadTextContent('definition.json'))

module policyDefinition '../../modules/policyDefinition.bicep' = {
  name: policyName
  scope: az.managementGroup(Def_MGID)
  params: {
    policyName: policyName
    displayName: displayName
    description: description
    category: category
    policyRuleFile: policyRuleFile
  }
}

module policyAssignment '../../modules/policyAssignment.bicep' = {
  name: policyName
  scope: az.managementGroup(Assign_MGID)
  params: {
    assignmentName: policyName
    policyDefinitionId: policyDefinition.outputs.policyDefinitionId
    regionAbbreviation: location
  }
}

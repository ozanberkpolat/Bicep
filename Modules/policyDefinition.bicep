targetScope = 'managementGroup'

param policyName string
param displayName string
param description string
param category string
param policyRuleFile object



resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: policyName
  properties: {
    displayName: displayName
    description: description
    mode: 'Indexed'
    policyRule: policyRuleFile
    metadata: {
      category: category
    }
  }
}

output policyDefinitionId string = policyDefinition.id

extension microsoftGraphV1

@description('UPN/email for user, AppId for service principal, or display name for group')
param principalIdentifier string

@description('Principal type: User, Group, ServicePrincipal')
param principalType string = 'User'

// Lookup principal in Graph depending on type
resource principalUser 'microsoft.graph/users@v1.0' existing = if (principalType == 'User') {
  userPrincipalName: principalIdentifier
}

resource principalGroup 'microsoft.graph/groups@v1.0' existing = if (principalType == 'Group') {
  uniqueName: principalIdentifier
}

resource principalSP 'microsoft.graph/servicePrincipals@v1.0' existing = if (principalType == 'ServicePrincipal') {
  appId:principalIdentifier
}

// Resolve principal ID dynamically
var userId = principalUser != null ? principalUser!.id : ''
var groupId = principalGroup != null ? principalGroup!.id : ''
var spId = principalSP != null ? principalSP!.id : ''

var principalId = principalType == 'User' ? userId : principalType == 'Group' ? groupId : principalType == 'ServicePrincipal' ? spId : principalIdentifier


output objectId string = principalId

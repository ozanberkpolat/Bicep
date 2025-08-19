param principalIdentifier string
param kvName string
param roleName string


module findPrincipalId '../../../modules/.shared/findPrincipalID.bicep' = {
  params: {
    principalIdentifier: principalIdentifier
  }
}

module KV_RoleAssign '../../../modules/roleAssignment-KV.bicep' = {
  params: {
    principalObjectId: findPrincipalId.outputs.objectId
    resourceName: kvName
    roleName: roleName
  }
}

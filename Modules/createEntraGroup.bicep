extension microsoftGraphV1

param displayName string
param mailEnabled bool
param securityEnabled bool
param uniqueName string 
param mailNickname string 

resource Entra_Group 'Microsoft.Graph/groups@v1.0' = {
  displayName: displayName
  mailEnabled: mailEnabled
  mailNickname: mailNickname
  securityEnabled: securityEnabled
  uniqueName: uniqueName
}

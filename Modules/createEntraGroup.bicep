targetScope = 'tenant'

// This module creates an Entra Group using the Microsoft Graph API v1.0

// Extension: Microsoft Graph API v1.0
extension microsoftGraphV1

// Parameters for the Entra Group
param displayName string
param mailEnabled bool = false
param securityEnabled bool = true
param uniqueName string = ''
param mailNickname string = ''

resource Entra_Group 'Microsoft.Graph/groups@v1.0' = {
  displayName: displayName
  mailEnabled: mailEnabled
  mailNickname: mailNickname
  securityEnabled: securityEnabled
  uniqueName: uniqueName
}

targetScope = 'managementGroup'
extension microsoftGraphV1
param displayName string

resource App_Registration 'Microsoft.Graph/applications@v1.0' = {
    displayName: displayName
    uniqueName: displayName
}

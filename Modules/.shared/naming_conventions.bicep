param projectName string
param regionAbbreviation string
param subscriptionName string

// Normalize the subscription name for consistent naming -> This turns Gunvor-CloudOps-Test into cloudopstest
var normalizedSubscriptionName = toLower('${split(subscriptionName, '-')[1]}${split(subscriptionName, '-')[2]}')

// Resource name variables (A→Z)
var appServicePlanName       = 'plan-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var containerRegistryName    = toLower('cr${projectName}${regionAbbreviation}')
var dataFactoryName          = 'adf-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var databricksWorkspaceName  = 'dbw-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var functionAppName          = 'func-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var keyVaultName             = 'kv-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ManagedDevOpsPoolName    = 'mdp-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var NSGName                  = 'nsg-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var redisCacheName           = 'redis-${projectName}-${regionAbbreviation}'
var routeTableName           = 'rt-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var storageAccountName       = toLower('gun${projectName}${regionAbbreviation}')
var webAppName               = 'app-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var managedIdentity          = 'mi-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'

// Private endpoint name variables (A→Z)
var pe_acr              = 'pe-${containerRegistryName}-${regionAbbreviation}'
var pe_adf_datafactory  = 'pe-adf-${projectName}-datafactory-${regionAbbreviation}'
var pe_adf_portal       = 'pe-adf-${projectName}-portal-${regionAbbreviation}'
var pe_apim             = 'pe-apim-${projectName}-${regionAbbreviation}' // assuming apimName not a separate var
var pe_blob             = 'pe-${storageAccountName}-blob-${regionAbbreviation}'
var pe_dbw_api          = 'pe-dbw-${projectName}-api-${regionAbbreviation}'
var pe_dbw_auth         = 'pe-dbw-${projectName}-auth-${regionAbbreviation}'
var pe_file             = 'pe-${storageAccountName}-file-${regionAbbreviation}'
var pe_generic          = 'pe-${projectName}-${regionAbbreviation}'
var pe_keyVault         = 'pe-${keyVaultName}-${regionAbbreviation}'
var pe_queue            = 'pe-${storageAccountName}-queue-${regionAbbreviation}'
var pe_table            = 'pe-${storageAccountName}-table-${regionAbbreviation}'
var pe_web              = 'pe-${webAppName}-${regionAbbreviation}'

// Resource Naming Outputs (A→Z)
output appServicePlanName       string = appServicePlanName
output containerRegistryName    string = containerRegistryName
output dataFactoryName          string = dataFactoryName
output databricksWorkspaceName  string = databricksWorkspaceName
output functionAppName          string = functionAppName
output keyVaultName             string = keyVaultName
output ManagedDevOpsPoolName    string = ManagedDevOpsPoolName
output NSGName                  string = NSGName
output redisCacheName           string = redisCacheName
output routeTableName           string = routeTableName
output storageAccountName       string = storageAccountName
output webAppName               string = webAppName
output managedIdentityName      string = managedIdentity

// Private Endpoint Naming Outputs (A→Z)
output pe_acr             string = pe_acr
output pe_adf_datafactory string = pe_adf_datafactory
output pe_adf_portal      string = pe_adf_portal
output pe_apim            string = pe_apim
output pe_blob            string = pe_blob
output pe_dbw_api         string = pe_dbw_api
output pe_dbw_auth        string = pe_dbw_auth
output pe_file            string = pe_file
output pe_generic         string = pe_generic
output pe_keyVault        string = pe_keyVault
output pe_queue           string = pe_queue
output pe_table           string = pe_table
output pe_web             string = pe_web

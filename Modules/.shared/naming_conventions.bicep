param projectName string
param regionAbbreviation string
param subscriptionName string

// Normalize the subscription name for consistent naming -> This turns Gunvor-CloudOps-Test into cloudopstest
var normalizedSubscriptionName = toLower('${split(subscriptionName, '-')[1]}${split(subscriptionName, '-')[2]}')


// Resource name variables (A→Z)
var appServicePlan                = 'plan-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var appServicePlanLnx             = 'plan-${normalizedSubscriptionName}-${projectName}-lnx-${regionAbbreviation}'
var AppInsights                   = 'appi-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var containerRegistry             = toLower('cr${projectName}${regionAbbreviation}')
var ContainerApp                  = 'ca-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ContainerAppEnv               = 'cae-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var dataFactory                   = 'adf-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var databricksWorkspace           = 'dbw-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var functionApp                   = 'func-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var functionAppLnx                = 'func-${normalizedSubscriptionName}-${projectName}-lnx-${regionAbbreviation}'
var keyVault                      = 'kv-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ManagedDevOpsPool             = 'mdp-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var NSGName                       = 'nsg-sn-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var redisCache                    = 'redis-${projectName}-${regionAbbreviation}'
var routeTable                    = 'rt-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ServiceBus                    = 'sbns-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var storageAccount                = toLower('gun${replace(projectName, '-', '')}${replace(regionAbbreviation, '-', '')}')
var vNet                          = 'vnet-${normalizedSubscriptionName}-${regionAbbreviation}'
var webApp                        = 'app-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var webAppLnx                     = 'app-${normalizedSubscriptionName}-${projectName}-lnx-${regionAbbreviation}'
var managedIdentity               = 'mi-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var logAnalyticsWorkspace         = 'log-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'


// Private endpoint name variables (A→Z)
var pe_acr                        = 'pe-${containerRegistry}-${regionAbbreviation}'
var pe_adf_datafactory            = 'pe-adf-${projectName}-datafactory-${regionAbbreviation}'
var pe_adf_portal                 = 'pe-adf-${projectName}-portal-${regionAbbreviation}'
var pe_apim                       = 'pe-apim-${projectName}-${regionAbbreviation}' // assuming apimName not a separate var
var pe_blob                       = 'pe-${storageAccount}-blob-${regionAbbreviation}'
var pe_ca                         = 'pe-${ContainerApp}'
var pe_cae                        = 'pe-${ContainerAppEnv}'
var pe_dbw_api                    = 'pe-dbw-${projectName}-api-${regionAbbreviation}'
var pe_dbw_auth                   = 'pe-dbw-${projectName}-auth-${regionAbbreviation}'
var pe_file                       = 'pe-${storageAccount}-file-${regionAbbreviation}'
var pe_func                       = 'pe-${functionApp}'
var pe_func_lnx                   = 'pe-${functionAppLnx}'
var pe_keyVault                   = 'pe-${keyVault}'
var pe_servicebus                 = 'pe-${ServiceBus}'
var pe_queue                      = 'pe-${storageAccount}-queue-${regionAbbreviation}'
var pe_table                      = 'pe-${storageAccount}-table-${regionAbbreviation}'
var pe_web                        = 'pe-${webApp}-${regionAbbreviation}'
var pe_web_lnx                    = 'pe-${webAppLnx}-${regionAbbreviation}'


// Private endpoint name variables (A→Z)
var pe_acr_nic                    = 'pe-${containerRegistry}-nic'
var pe_adf_datafactory_nic        = 'pe-adf-${projectName}-datafactory-${regionAbbreviation}-nic'
var pe_adf_portal_nic             = 'pe-adf-${projectName}-portal-${regionAbbreviation}-nic'
var pe_apim_nic                   = 'pe-apim-${projectName}-${regionAbbreviation}-nic'
var pe_blob_nic                   = '${pe_blob}-nic'
var pe_ca_nic                     = '${pe_ca}-nic'
var pe_cae_nic                    = '${pe_cae}-nic'
var pe_dbw_api_nic                = '${pe_dbw_api}-nic'
var pe_dbw_auth_nic               = '${pe_dbw_auth}-nic'
var pe_file_nic                   = '${pe_file}-nic'
var pe_func_nic                   = '${pe_func}-nic'
var pe_func_lnx_nic               = '${pe_func_lnx}-nic'
var pe_keyVault_nic               = '${pe_keyVault}-nic'
var pe_servicebus_nic             = '${pe_servicebus}-nic'
var pe_queue_nic                  = '${pe_queue}-nic'
var pe_table_nic                  = '${pe_table}-nic'
var pe_web_nic                    = '${pe_web}-nic'
var pe_web_lnx_nic                = '${pe_web_lnx}-nic'

// Resource Naming Outputs (A→Z)
output appServicePlan               string = appServicePlan
output appServicePlanLnx            string = appServicePlanLnx
output AppInsights                  string = AppInsights
output containerRegistry            string = containerRegistry
output ContainerApp                 string = ContainerApp
output ContainerAppEnv              string = ContainerAppEnv
output dataFactoryName              string = dataFactory
output databricksWorkspace          string = databricksWorkspace
output functionApp                  string = functionApp
output functionAppLnx               string = functionAppLnx
output keyVault                     string = keyVault
output ManagedDevOpsPool            string = ManagedDevOpsPool
output NSGName                      string = NSGName
output redisCache                   string = redisCache
output routeTable                   string = routeTable
output storageAccount               string = storageAccount
output serviceBus                   string = ServiceBus
output vNet                         string = vNet
output webApp                       string = webApp
output webAppLnx                    string = webAppLnx
output managedIdentity              string = managedIdentity
output logAnalyticsWorkspace        string = logAnalyticsWorkspace

// Private Endpoint Naming Outputs (A→Z)
output pe_acr                       string = pe_acr
output pe_adf_datafactory           string = pe_adf_datafactory
output pe_adf_portal                string = pe_adf_portal
output pe_apim                      string = pe_apim
output pe_blob                      string = pe_blob
output pe_ca                        string = pe_ca
output pe_cae                       string = pe_cae
output pe_dbw_api                   string = pe_dbw_api
output pe_dbw_auth                  string = pe_dbw_auth
output pe_file                      string = pe_file
output pe_func                      string = pe_func
output pe_func_lnx                  string = pe_func_lnx
output pe_keyVault                  string = pe_keyVault
output pe_serviceBus                string = pe_servicebus
output pe_queue                     string = pe_queue
output pe_table                     string = pe_table
output pe_web                       string = pe_web
output pe_web_lnx                   string = pe_web_lnx

// Network Interface Card Naming Outputs (A→z)
output pe_acr_nic                   string = pe_acr_nic
output pe_adf_datafactory_nic       string = pe_adf_datafactory_nic
output pe_adf_portal_nic            string = pe_adf_portal_nic
output pe_apim_nic                  string = pe_apim_nic
output pe_blob_nic                  string = pe_blob_nic
output pe_ca_nic                    string = pe_ca_nic
output pe_cae_nic                   string = pe_cae_nic
output pe_dbw_api_nic               string = pe_dbw_api_nic
output pe_dbw_auth_nic              string = pe_dbw_auth_nic
output pe_file_nic                  string = pe_file_nic
output pe_func_nic                  string = pe_func_nic
output pe_func_lnx_nic              string = pe_func_lnx_nic
output pe_keyVault_nic              string = pe_keyVault_nic
output pe_serviceBus_nic            string = pe_servicebus_nic
output pe_queue_nic                 string = pe_queue_nic
output pe_table_nic                 string = pe_table_nic
output pe_web_nic                   string = pe_web_nic
output pe_web_lnx_nic               string = pe_web_lnx_nic

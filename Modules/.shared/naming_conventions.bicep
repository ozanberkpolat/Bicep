// Parameters (A→Z)
param projectName string
param regionAbbreviation string
param subscriptionName string

// Normalize the subscription name for consistent naming -> Gunvor-CloudOps-Test → cloudopstest
var normalizedSubscriptionName = toLower('${split(subscriptionName, '-')[1]}${split(subscriptionName, '-')[2]}')

// Resource name variables (A→Z)
var AppInsights                   = 'appi-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var appServicePlan                = 'plan-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ContainerApp                  = 'ca-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ContainerAppEnv               = 'cae-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var containerRegistry             = toLower('cr${projectName}${regionAbbreviation}')
var CosmosDb                      = 'cdb-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var dataFactory                   = 'adf-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var databricksWorkspace           = 'dbw-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var functionApp                   = 'func-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var keyVault                      = 'kv-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var logAnalyticsWorkspace         = 'log-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var logicApp                      = 'lapp-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var managedIdentity               = 'id-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ManagedDevOpsPool             = 'mdp-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var redisCache                    = 'redis-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var routeTable                    = 'rt-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var ServiceBus                    = 'sbns-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var storageAccount                = toLower('gun${replace(projectName, '-', '')}${replace(regionAbbreviation, '-', '')}')
var synapseWorkspace              = 'synw-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'
var vNet                          = 'vnet-${normalizedSubscriptionName}-${regionAbbreviation}'
var webApp                        = 'app-${normalizedSubscriptionName}-${projectName}-${regionAbbreviation}'

// Private endpoint name variables (A→Z)
var pe_acr                        = 'pe-${containerRegistry}-${regionAbbreviation}'
var pe_adf_datafactory            = '${dataFactory}-datafactory-${regionAbbreviation}'
var pe_adf_portal                 = '${dataFactory}-portal-${regionAbbreviation}'
var pe_blob                       = 'pe-${storageAccount}-blob-${regionAbbreviation}'
var pe_ca                         = 'pe-${ContainerApp}'
var pe_cae                        = 'pe-${ContainerAppEnv}'
var pe_cdb                        = 'pe-${CosmosDb}'
var pe_dbw_api                    = 'pe-dbw-${projectName}-api-${regionAbbreviation}'
var pe_dbw_auth                   = 'pe-dbw-${projectName}-auth-${regionAbbreviation}'
var pe_file                       = 'pe-${storageAccount}-file-${regionAbbreviation}'
var pe_func                       = 'pe-${functionApp}'
var pe_keyVault                   = 'pe-${keyVault}'
var pe_logicApp                   = 'pe-${logicApp}'
var pe_queue                      = 'pe-${storageAccount}-queue-${regionAbbreviation}'
var pe_redis                      = 'pe-${redisCache}'
var pe_servicebus                 = 'pe-${ServiceBus}'
var pe_synapse                    = 'pe-${synapseWorkspace}'
var pe_table                      = 'pe-${storageAccount}-table-${regionAbbreviation}'
var pe_web                        = 'pe-${webApp}-${regionAbbreviation}'

// Private endpoint NIC name variables (A→Z)
var pe_acr_nic                    = '${pe_acr}-nic'
var pe_adf_datafactory_nic        = '${pe_adf_datafactory}-nic'
var pe_adf_portal_nic             = '${pe_adf_portal}-nic'
var pe_blob_nic                   = '${pe_blob}-nic'
var pe_ca_nic                     = '${pe_ca}-nic'
var pe_cae_nic                    = '${pe_cae}-nic'
var pe_cdb_nic                    = '${pe_cdb}-nic'
var pe_dbw_api_nic                = '${pe_dbw_api}-nic'
var pe_dbw_auth_nic               = '${pe_dbw_auth}-nic'
var pe_file_nic                   = '${pe_file}-nic'
var pe_func_nic                   = '${pe_func}-nic'
var pe_keyVault_nic               = '${pe_keyVault}-nic'
var pe_logicApp_nic               = '${pe_logicApp}-nic'
var pe_queue_nic                  = '${pe_queue}-nic'
var pe_redis_nic                  = '${pe_redis}-nic'
var pe_servicebus_nic             = '${pe_servicebus}-nic'
var pe_synapse_nic                = '${pe_synapse}-nic'
var pe_table_nic                  = '${pe_table}-nic'
var pe_web_nic                    = '${pe_web}-nic'

// ----------------------------
// Local types for autocomplete
// ----------------------------
type Resources = {
  AppInsights: string
  appServicePlan: string
  ContainerApp: string
  ContainerAppEnv: string
  containerRegistry: string
  CosmosDb:string
  dataFactory: string
  databricksWorkspace: string
  functionApp: string
  keyVault: string
  logAnalyticsWorkspace: string
  logicApp: string
  managedIdentity: string
  ManagedDevOpsPool: string
  redisCache: string
  routeTable: string
  serviceBus: string
  storageAccount: string
  synapseWorkspace: string
  vNet: string
  webApp: string
}

type PrivateEndpoints = {
  pe_acr: string
  pe_adf_datafactory: string
  pe_adf_portal: string
  pe_blob: string
  pe_ca: string
  pe_cae: string
  pe_cdb: string
  pe_dbw_api: string
  pe_dbw_auth: string
  pe_file: string
  pe_func: string
  pe_keyVault: string
  pe_logicApp: string
  pe_queue: string
  pe_redis: string
  pe_serviceBus: string
  pe_synapse: string
  pe_table: string
  pe_web: string
}

type NICs = {
  pe_acr_nic: string
  pe_adf_datafactory_nic: string
  pe_adf_portal_nic: string
  pe_blob_nic: string
  pe_ca_nic: string
  pe_cae_nic: string
  pe_cdb_nic: string
  pe_dbw_api_nic: string
  pe_dbw_auth_nic: string
  pe_file_nic: string
  pe_func_nic: string
  pe_keyVault_nic: string
  pe_logicApp_nic: string
  pe_queue_nic: string
  pe_redis_nic: string
  pe_servicebus_nic: string
  pe_synapse_nic: string
  pe_table_nic: string
  pe_web_nic: string
}

// ----------------------------
// Consolidated outputs
// ----------------------------

output Resources Resources = {
  AppInsights: AppInsights
  appServicePlan: appServicePlan
  ContainerApp: ContainerApp
  ContainerAppEnv: ContainerAppEnv
  containerRegistry: containerRegistry
  CosmosDb: CosmosDb
  dataFactory: dataFactory
  databricksWorkspace: databricksWorkspace
  functionApp: functionApp
  keyVault: keyVault
  logAnalyticsWorkspace: logAnalyticsWorkspace
  logicApp: logicApp
  managedIdentity: managedIdentity
  ManagedDevOpsPool: ManagedDevOpsPool
  redisCache: redisCache
  routeTable: routeTable
  serviceBus: ServiceBus
  storageAccount: storageAccount
  synapseWorkspace: synapseWorkspace
  vNet: vNet
  webApp: webApp
}

output privateEndpoints PrivateEndpoints = {
  pe_acr: pe_acr
  pe_adf_datafactory: pe_adf_datafactory
  pe_adf_portal: pe_adf_portal
  pe_blob: pe_blob
  pe_ca: pe_ca
  pe_cae: pe_cae
  pe_cdb: pe_cdb
  pe_dbw_api: pe_dbw_api
  pe_dbw_auth: pe_dbw_auth
  pe_file: pe_file
  pe_func: pe_func
  pe_keyVault: pe_keyVault
  pe_logicApp: pe_logicApp
  pe_queue: pe_queue
  pe_redis: pe_redis
  pe_serviceBus: pe_servicebus
  pe_synapse: pe_synapse
  pe_table: pe_table
  pe_web: pe_web
}

output NICs NICs = {
  pe_acr_nic: pe_acr_nic
  pe_adf_datafactory_nic: pe_adf_datafactory_nic
  pe_adf_portal_nic: pe_adf_portal_nic
  pe_blob_nic: pe_blob_nic
  pe_ca_nic: pe_ca_nic
  pe_cae_nic: pe_cae_nic
  pe_cdb_nic: pe_cdb_nic
  pe_dbw_api_nic: pe_dbw_api_nic
  pe_dbw_auth_nic: pe_dbw_auth_nic
  pe_file_nic: pe_file_nic
  pe_func_nic: pe_func_nic
  pe_keyVault_nic: pe_keyVault_nic
  pe_logicApp_nic: pe_logicApp_nic
  pe_queue_nic: pe_queue_nic
  pe_redis_nic: pe_redis_nic
  pe_servicebus_nic: pe_servicebus_nic
  pe_synapse_nic: pe_synapse_nic
  pe_table_nic: pe_table_nic
  pe_web_nic: pe_web_nic
}

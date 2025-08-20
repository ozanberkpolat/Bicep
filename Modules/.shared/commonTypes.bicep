import { securityRuleType } from 'br/public:avm/res/network/network-security-group:0.5.1'

@export()
type regionType = 'swn' | 'usc' | 'weu' | 'sea'

@export()
type environmentType = 'dev' | 'test' | 'prod'

@export()
type subnetType = {
  name: string
  addressPrefix: string
  delegation: string?
  rules: securityRuleType[]
}

@export()
type webAppDefinition = {
  name: string
  containerImage: string?
  appSettings: object 
  slots: string[]
}

@export()
type OSType = 'Linux' | 'Windows Server 2022' | 'Windows Server 2019' | 'Windows'

@export()
type vmSizeType = 'small' | 'medium' | 'large' | 'xlarge' | '2xlarge' | '4xlarge'

@export()
type ASP_SKU = 'P1V3' | 'P0V3'

@export()
type storageAccountKind = 'StorageV2' | 'BlobStorage' | 'FileStorage'

@export()
type RunTimeType = 'Dotnet' | 'Python'

@export()
type regionDefinitionType = {
  name: string
  region: string
  nextHopIp: string
  dnsServers: string[]
  firewall: {
    external: string
    internal: string
  }
}

@export()
func getLocation(region regionType) regionDefinitionType => {
  name: region
  region: region == 'swn' ? 'switzerlandnorth' 
        : region == 'usc' ? 'southcentralus' 
        : region == 'weu'  ? 'westeurope' 
        : region == 'sea' ? 'southeastasia'  
        : 'unknown'
  nextHopIp: region == 'usc' ? 'USC-NEXT-HOP-IP' : 'RoW-NEXT-HOP-IP'
  dnsServers: region == 'usc' ? ['USC-DNS-1', 'USC-DNS-2'] : ['RoW-DNS-1', 'RoW-DNS-2']
  firewall: {
    external: '/subscriptions/SUBSCRIPTION-NAME-HERE/resourceGroups/rg-fortigate_ext-${region}/providers/Microsoft.Network/virtualNetworks/vnet-fortigate_ext-${region}'
    internal: '/subscriptions/SUBSCRIPTION-NAME-HERE/resourceGroups/rg-fortigate_int-${region}/providers/Microsoft.Network/virtualNetworks/vnet-fortigate_int-${region}'
  }
}

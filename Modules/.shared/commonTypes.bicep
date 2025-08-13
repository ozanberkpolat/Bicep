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
type storageAccountKind = 'StorageV2' | 'BlobStorage' | 'FileStorage'

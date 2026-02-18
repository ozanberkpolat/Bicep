param HubVNetAddressPrefixes array
param DNServers array
param location string
module hubNetworking 'br/public:avm/ptn/network/hub-networking:0.5.0' = {
  params: {
    hubVirtualNetworks: {
      'vnet-hub-gwc': {
        addressPrefixes: HubVNetAddressPrefixes
        bastionHost: {
          disableCopyPaste: true
          enableFileCopy: false
          enableIpConnect: false
          enableShareableLink: false
          scaleUnits: 2
          skuName: 'Developer'
        }
        dnsServers: DNServers
        enableAzureFirewall: false
        enableBastion: true
        enablePeering: true
        flowTimeoutInMinutes: 30
        location: location
        subnets: [
          {
            name: 'AzureBastionSubnet'
            addressPrefix: '192.168.0.0/26'
            
          }
          {
            name: 'snet-hub-firewall-internal'
            addressPrefix: '192.168.1.0/24'
          }
        ]
        tags: {
          Environment: 'Prod'
        }
        vnetEncryption: false
        vnetEncryptionEnforcement: 'AllowUnencrypted'
      }
    }
    
    location: location
  }
}

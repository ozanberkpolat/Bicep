param HubVirtualNetworkResourceId string
module privateLinkPrivateDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.2' = {
  params: {
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: HubVirtualNetworkResourceId
      }
    ]
  }
}

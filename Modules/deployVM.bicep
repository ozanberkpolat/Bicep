// This module deploys a Virtual Machine

//Importing necessary types
import { regionType, OSType, vmSizeType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param VMName string
param subnetName string
param vNetRG string
param vNetName string
param TypeofOS OSType
param SizeOfVM vmSizeType

// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region
var vmSize = loadJsonContent('.shared/vmSizes.json')
var vmSizeValue = vmSize[SizeOfVM]
var OSMapping = loadJsonContent('.shared/VM_OS.json')
var OS = OSMapping[TypeofOS]

// Flags for specific Windows versions
var isWindows2019 = toLower(TypeofOS) == 'windows server 2019'
var isWindows2022 = toLower(TypeofOS) == 'windows server 2022'

// Windows or Linux check (generic)
var isWindows = isWindows2019 || isWindows2022

var imageReference = isWindows2019
  ? {
      id: OS.resourceId
    }
  : isWindows2022
  ? {
      id: OS.resourceId
    }
  : {
      publisher: OS.Linux.publisher
      offer: OS.Linux.offer
      sku: OS.Linux.sku
      version: OS.Linux.version
    }

// Existing VNet and Subnet resources
resource Existing_VNet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: vNetName
  scope: resourceGroup(vNetRG)
}

resource Existing_Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: Existing_VNet
    name: subnetName
}

module VM 'br/public:avm/res/compute/virtual-machine:0.17.0' = {
  params: {
    name: VMName
    location: location
    adminUsername: 'gunvoradmin'
    availabilityZone: -1
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            subnetResourceId: Existing_Subnet.id
            privateIPAllocationMethod: 'Dynamic'
            privateIPAddressVersion: 'IPv4'            
          }
        ]
      }
    ]
    adminPassword: 'P@ssw0rd1234!'
    osDisk:{
      managedDisk: {}
    }
    managedIdentities:{
      systemAssigned: true
    }
    osType: OS.type
    vmSize: vmSizeValue
    secureBootEnabled: true
    computerName: VMName
    imageReference: imageReference
    publicNetworkAccess: 'Disabled'
    licenseType: isWindows ? 'Windows_Server' : ''
  }
}

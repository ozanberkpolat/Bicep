// This module deploys a Virtual Machine

//Importing necessary types
import { regionType, OSType, vmSizeType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param VMName string
param TypeofOS OSType
param SizeOfVM vmSizeType
param subNetId string

// Importing shared resources and configurations
var vmSize = loadJsonContent('.shared/vmSizes.json')
var vmSizeValue = vmSize[SizeOfVM]
var OSMapping = loadJsonContent('.shared/VM_OS.json')
var OS = OSMapping[TypeofOS]

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

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


module VM 'br/public:avm/res/compute/virtual-machine:0.17.0' = {
  params: {
    name: VMName
    location: location.region
    adminUsername: 'gunvoradmin'
    availabilityZone: -1
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            subnetResourceId: subNetId
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

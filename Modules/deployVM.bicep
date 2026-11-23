// This module deploys a Virtual Machine (Windows or Linux) on top of the AVM virtual-machine module.
//
// Changes against the first version of this module:
//  - adminUsername is now a REQUIRED parameter (it used to be a literal in the module).
//  - New optional parameters, all defaulting to the previous behaviour: trustedLaunch, encryptionAtHost, tags,
//    availabilityZone, computerName, osDiskSizeGB, dataDisks, privateIPAddress, enableAcceleratedNetworking,
//    sshPublicKey, maintenanceConfigurationResourceId, backup*, dataCollectionRuleResourceIds.
//  - New TypeofOS values: 'Windows Server 2025', 'Ubuntu 24.04', 'RHEL 10' (marketplace images, see .shared/VM_OS.json).
//    'Windows Server 2022' / 'Windows Server 2019' still point at the custom gallery image in VM_OS.json.
//
// To turn Trusted Launch on, set trustedLaunch = true (it needs a Gen2 image; the marketplace images above are Gen2,
// check that your custom gallery image is too). Off by default because switching it on changes the VM security type.

//Importing necessary types
import { regionType, OSType, vmSizeType, regionDefinitionType, getLocation } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param VMName string
param TypeofOS OSType
param SizeOfVM vmSizeType
param peSubnetResourceId string

@description('Local administrator user name. Required: there is no default on purpose.')
param adminUsername string

@description('Local administrator password. Pass it from a secret source (Key Vault reference, environment variable in the .bicepparam). Leave empty only for Linux VMs that use sshPublicKey.')
@secure()
param adminPassword string = ''

param tags object = {}

@description('Computer (host) name inside the OS. Defaults to the VM name. Windows allows 15 characters at most.')
param computerName string = VMName

@description('Availability zone. -1 means no zone.')
@allowed([ -1, 1, 2, 3 ])
param availabilityZone int = -1

@description('Trusted Launch (securityType TrustedLaunch with Secure Boot and vTPM). Default false keeps the earlier behaviour (Secure Boot flag only).')
param trustedLaunch bool = false

@description('Encryption at host. Needs the Microsoft.Compute/EncryptionAtHost feature registered on the subscription.')
param encryptionAtHost bool = true

@description('OS disk size in GB. 0 keeps the image default.')
param osDiskSizeGB int = 0

@description('Data disks in AVM format, e.g. [{ name: \'vm1-data-001\', diskSizeGB: 64, lun: 0, caching: \'None\', deleteOption: \'Detach\', managedDisk: { storageAccountType: \'Premium_LRS\' } }].')
param dataDisks array = []

@description('Static private IP address. Empty means Dynamic.')
param privateIPAddress string = ''

@description('Accelerated networking. Not set: AVM default. The chosen VM size must support it.')
param enableAcceleratedNetworking bool?

@description('SSH public key for adminUsername. When set, password authentication is disabled (Linux only).')
param sshPublicKey string = ''

@description('Maintenance configuration resource ID. When set, patch orchestration is switched to AutomaticByPlatform (customer-managed schedule).')
param maintenanceConfigurationResourceId string = ''

@description('Recovery Services vault for Azure Backup. Leave all three backup parameters empty to skip backup enrolment.')
param backupVaultName string = ''
param backupPolicyName string = ''
param backupVaultResourceGroup string = ''

@description('Data collection rule resource IDs. When not empty, the Azure Monitor agent is installed and associated with them.')
param dataCollectionRuleResourceIds string[] = []

// Importing shared resources and configurations
var vmSize = loadJsonContent('.shared/vmSizes.json')
var vmSizeValue = vmSize[SizeOfVM]
var OSMapping = loadJsonContent('.shared/VM_OS.json')
var OS = OSMapping[TypeofOS]

// Get the region definition based on the provided region parameter
var location regionDefinitionType = getLocation(regionAbbreviation)

var isWindows = OS.type == 'Windows'

// A gallery entry carries a resourceId, a marketplace entry carries publisher/offer/sku/version
var imageReference = contains(OS, 'resourceId')
  ? {
      id: OS.resourceId
    }
  : {
      publisher: OS.publisher
      offer: OS.offer
      sku: OS.sku
      version: OS.version
    }

var useSshKey = !isWindows && !empty(sshPublicKey)
var useMaintenance = !empty(maintenanceConfigurationResourceId)

module VM 'br/public:avm/res/compute/virtual-machine:0.17.0' = {
  params: {
    name: VMName
    location: location.region
    tags: tags
    adminUsername: adminUsername
    availabilityZone: availabilityZone
    nicConfigurations: [
      {
        enableAcceleratedNetworking: enableAcceleratedNetworking
        ipConfigurations: [
          {
            subnetResourceId: peSubnetResourceId
            privateIPAllocationMethod: empty(privateIPAddress) ? 'Dynamic' : 'Static'
            privateIPAddress: empty(privateIPAddress) ? null : privateIPAddress
            privateIPAddressVersion: 'IPv4'
          }
        ]
      }
    ]
    adminPassword: adminPassword
    disablePasswordAuthentication: useSshKey
    publicKeys: useSshKey
      ? [
          {
            path: '/home/${adminUsername}/.ssh/authorized_keys'
            keyData: sshPublicKey
          }
        ]
      : []
    osDisk: {
      diskSizeGB: osDiskSizeGB == 0 ? null : osDiskSizeGB
      managedDisk: {}
    }
    dataDisks: dataDisks
    managedIdentities: {
      systemAssigned: true
    }
    osType: OS.type
    vmSize: vmSizeValue
    secureBootEnabled: true
    securityType: trustedLaunch ? 'TrustedLaunch' : null
    vTpmEnabled: trustedLaunch ? true : null
    encryptionAtHost: encryptionAtHost
    computerName: computerName
    imageReference: imageReference
    publicNetworkAccess: 'Disabled'
    licenseType: isWindows ? 'Windows_Server' : ''
    // Patching: only when a maintenance configuration is supplied
    patchAssessmentMode: useMaintenance ? 'AutomaticByPlatform' : null
    patchMode: useMaintenance ? 'AutomaticByPlatform' : null
    bypassPlatformSafetyChecksOnUserSchedule: useMaintenance ? true : null
    maintenanceConfigurationResourceId: maintenanceConfigurationResourceId
    backupVaultName: backupVaultName
    backupPolicyName: backupPolicyName
    backupVaultResourceGroup: backupVaultResourceGroup
    extensionMonitoringAgentConfig: {
      enabled: !empty(dataCollectionRuleResourceIds)
      dataCollectionRuleAssociations: [
        for dcrId in dataCollectionRuleResourceIds: {
          name: '${last(split(dcrId, '/'))}-association'
          dataCollectionRuleResourceId: dcrId
        }
      ]
    }
  }
}

output vmResourceId string = VM.outputs.resourceId
output vmName string = VM.outputs.name

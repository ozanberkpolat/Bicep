// This module deploys a Virtual Machine together with its NIC (static or dynamic private IP) as plain resources,
// without the region/naming framework or AVM. Use it for one-off servers (for example a domain controller, an FTP
// test server) where the exact IP, image and disks must be chosen by hand. Scope: resource group.
//
// Lessons kept from the ARM deployment this module replaces:
//  - Patching uses AutomaticByPlatform with bypassPlatformSafetyChecksOnUserSchedule, so a maintenance
//    configuration can drive the schedule.
//  - The NIC and OS disk use deleteOption 'Detach': deleting the VM never silently deletes the disk or the NIC.
//  - A domain-controller data disk (NTDS/SYSVOL) must have caching 'None'; that is the default for dataDisks below.
//  - The admin password can be random and unknown: the default is generated with newGuid(), nobody holds it, and
//    the first login needs "Reset password" in the portal (or pass your own secure value). newGuid() is only legal
//    as a parameter default, which is why it lives there.

@description('VM name. Also the Azure resource name; the NIC is "<name>-nic" and the OS disk "<name>-osdisk".')
param vmName string

@description('Computer (host) name inside the OS. Windows allows 15 characters at most.')
@maxLength(15)
param computerName string = take(vmName, 15)

param location string = resourceGroup().location

@description('Resource ID of the subnet the NIC joins.')
param subnetResourceId string

@description('Static private IP address inside the subnet. Empty means Dynamic.')
param privateIPAddress string = ''

@description('VM size. Check that it supports accelerated networking when enableAcceleratedNetworking is true.')
param vmSize string = 'Standard_D2s_v5'

@allowed([ 'Windows', 'Linux' ])
param osType string = 'Windows'

@description('Marketplace image. Default is Windows Server 2022 Azure Edition (Gen2).')
param imageReference object = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
}

param adminUsername string

@description('Admin password. Default is random and unknown on purpose (see header): reset it in the portal at first login, or pass a secret from Key Vault.')
@secure()
param adminPassword string = 'Xq7!${newGuid()}'

@description('SSH public key (Linux). When set, password authentication is disabled.')
param sshPublicKey string = ''

@description('Trusted Launch (Secure Boot and vTPM). Needs a Gen2 image.')
param trustedLaunch bool = true

@description('Azure Hybrid Benefit for Windows Server.')
param azureHybridBenefit bool = true

param enableAcceleratedNetworking bool = true

param osDiskSizeGB int = 128

@allowed([ 'Premium_LRS', 'StandardSSD_LRS', 'Standard_LRS', 'Premium_ZRS', 'StandardSSD_ZRS' ])
param diskSku string = 'Premium_LRS'

@description('Data disks to create empty: [{ sizeGB: 32, caching: \'None\' }]. LUNs are assigned in order, names are "<vm>-datadisk-001".')
param dataDisks array = []

param tags object = {}

var isWindows = osType == 'Windows'
var useSshKey = !isWindows && !empty(sshPublicKey)

resource nic 'Microsoft.Network/networkInterfaces@2025-05-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetResourceId
          }
          primary: true
          privateIPAllocationMethod: empty(privateIPAddress) ? 'Dynamic' : 'Static'
          privateIPAddress: empty(privateIPAddress) ? null : privateIPAddress
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    licenseType: isWindows && azureHybridBenefit ? 'Windows_Server' : null
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: useSshKey ? null : adminPassword
      allowExtensionOperations: true
      windowsConfiguration: isWindows
        ? {
            provisionVMAgent: true
            enableAutomaticUpdates: true
            patchSettings: {
              patchMode: 'AutomaticByPlatform'
              assessmentMode: 'AutomaticByPlatform'
              automaticByPlatformSettings: {
                bypassPlatformSafetyChecksOnUserSchedule: true
              }
            }
          }
        : null
      linuxConfiguration: isWindows
        ? null
        : {
            disablePasswordAuthentication: useSshKey
            provisionVMAgent: true
            ssh: useSshKey
              ? {
                  publicKeys: [
                    {
                      path: '/home/${adminUsername}/.ssh/authorized_keys'
                      keyData: sshPublicKey
                    }
                  ]
                }
              : null
            patchSettings: {
              patchMode: 'AutomaticByPlatform'
              assessmentMode: 'AutomaticByPlatform'
              automaticByPlatformSettings: {
                bypassPlatformSafetyChecksOnUserSchedule: true
              }
            }
          }
    }
    securityProfile: trustedLaunch
      ? {
          securityType: 'TrustedLaunch'
          uefiSettings: {
            secureBootEnabled: true
            vTpmEnabled: true
          }
        }
      : null
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: osDiskSizeGB
        managedDisk: {
          storageAccountType: diskSku
        }
        deleteOption: 'Detach'
      }
      dataDisks: [
        for (disk, i) in dataDisks: {
          lun: i
          name: '${vmName}-datadisk-${padLeft(string(i + 1), 3, '0')}'
          createOption: 'Empty'
          diskSizeGB: disk.sizeGB
          caching: disk.?caching ?? 'None'
          managedDisk: {
            storageAccountType: diskSku
          }
          deleteOption: 'Detach'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output vmResourceId string = vm.id
output nicResourceId string = nic.id
output principalId string = vm.identity.principalId
output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress

// This module deploys Entra-joined AVD session hosts (Windows 11 multi-session by default) and registers them in an
// existing host pool. Scope: resource group of the VMs. The host pool must already exist and hold a valid
// registration token (deployAvdHostPool with createRegistrationToken = true, in the same deployment or earlier).
//
// Lessons kept from the source deployment:
//  - Registration = the DSC extension 'AddSessionHost' with the token in protectedSettings. The token never appears
//    in plain settings or outputs. aadJoin: true makes the agent register the host as Entra joined.
//  - The AADLoginForWindows extension does the Entra join; it must finish BEFORE the DSC extension (dependsOn).
//  - Users need two roles: Desktop Virtualization User on the app group (deployAvdHostPool userObjectIds) and
//    Virtual Machine User Login (or Administrator Login) on the VM or resource group.
//  - licenseType 'Windows_Client' is the Windows 11 multi-session / Microsoft 365 licence benefit.
//  - Disks and NICs are deleted with the VM (deleteOption 'Delete'): session hosts are cattle, not pets.
// UNTESTED: the DSC package URL is the one Microsoft's Add session host template used when this was written.
// Compare it with the current template in the portal (Host pool > Session hosts > Add) before relying on it.

param hostPoolName string

@description('Resource group of the host pool. Defaults to the group this module is deployed to.')
param hostPoolResourceGroup string = resourceGroup().name

param location string = resourceGroup().location

@description('Resource ID of the subnet for the session host NICs.')
param subnetResourceId string

param vmNamePrefix string = 'avd-sh'
param sessionHostCount int = 1

@description('First number used in the VM names (<prefix>-<n>), so a pool can be extended later.')
param startNumber int = 1

param vmSize string = 'Standard_D2s_v5'
param adminUsername string

@secure()
param adminPassword string

param imageReference object = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-24h2-avd'
  version: 'latest'
}

@description('DSC package that installs the AVD agent. See the UNTESTED note in the header.')
param dscPackageUrl string = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_1.0.03483.1387.zip'

param osDiskSku string = 'StandardSSD_LRS'

param tags object = {}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' existing = {
  scope: resourceGroup(hostPoolResourceGroup)
  name: hostPoolName
}

resource nic 'Microsoft.Network/networkInterfaces@2025-05-01' = [
  for i in range(startNumber, sessionHostCount): {
    name: 'nic-${vmNamePrefix}-${i}'
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
            privateIPAllocationMethod: 'Dynamic'
          }
        }
      ]
    }
  }
]

resource vm 'Microsoft.Compute/virtualMachines@2025-04-01' = [
  for (n, idx) in range(startNumber, sessionHostCount): {
    name: '${vmNamePrefix}-${n}'
    location: location
    tags: tags
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      licenseType: 'Windows_Client'
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: '${vmNamePrefix}-${n}'
        adminUsername: adminUsername
        adminPassword: adminPassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          provisionVMAgent: true
        }
      }
      storageProfile: {
        imageReference: imageReference
        osDisk: {
          createOption: 'FromImage'
          deleteOption: 'Delete'
          managedDisk: {
            storageAccountType: osDiskSku
          }
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: nic[idx].id
            properties: {
              deleteOption: 'Delete'
            }
          }
        ]
      }
      securityProfile: {
        securityType: 'TrustedLaunch'
        uefiSettings: {
          secureBootEnabled: true
          vTpmEnabled: true
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
]

resource entraJoin 'Microsoft.Compute/virtualMachines/extensions@2025-04-01' = [
  for (n, idx) in range(startNumber, sessionHostCount): {
    parent: vm[idx]
    name: 'AADLoginForWindows'
    location: location
    tags: tags
    properties: {
      publisher: 'Microsoft.Azure.ActiveDirectory'
      type: 'AADLoginForWindows'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
    }
  }
]

resource avdRegistration 'Microsoft.Compute/virtualMachines/extensions@2025-04-01' = [
  for (n, idx) in range(startNumber, sessionHostCount): {
    parent: vm[idx]
    name: 'Microsoft.PowerShell.DSC'
    location: location
    tags: tags
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.73'
      autoUpgradeMinorVersion: true
      settings: {
        modulesUrl: dscPackageUrl
        configurationFunction: 'Configuration.ps1\\AddSessionHost'
        properties: {
          HostPoolName: hostPool.name
          RegistrationInfoTokenCredential: {
            UserName: 'PLACEHOLDER_DO_NOT_USE'
            Password: 'PrivateSettingsRef:RegistrationInfoToken'
          }
          aadJoin: true
          mdmId: ''
          UseAgentDownloadEndpoint: true
        }
      }
      protectedSettings: {
        Items: {
          RegistrationInfoToken: hostPool.listRegistrationTokens().value[0].token
        }
      }
    }
    dependsOn: [
      entraJoin[idx]
    ]
  }
]

output sessionHostNames array = [for (n, idx) in range(startNumber, sessionHostCount): vm[idx].name]

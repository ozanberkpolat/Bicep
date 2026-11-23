// Training domain lab: one VNet, one domain controller (new forest) and one member server joined to it.
// Scope: resource group. Delete the resource group when the training ends.
//   az deployment group create -g <rg> -f main.bicep -p main.bicepparam
// UNTESTED: not deployed against a live subscription; run `az deployment group what-if` first.
//
// Lessons kept from the source lab:
//  - The DC gets a STATIC private IP and the VNet DNS points at it from the start, so the member server resolves
//    the forest as soon as it boots. The DC itself then resolves through its own new DNS role.
//  - Promotion runs with -NoRebootOnCompletion and a delayed restart, otherwise the Run Command is killed by the
//    reboot and ARM reports a failure for a promotion that actually worked.
//  - The member server is created only after the DC Run Command finished (dependsOn), then joined with the
//    JsonADDomainExtension (Options 3 = join + create the computer account if missing).
//  - RDP is allowed from ONE source range only (rdpSourceRange); a deny rule follows for the rest of the internet.
//  - Machines get public IPs for a short-lived lab. For anything longer, drop the public IPs and use Bastion.
//  - Auto-shutdown keeps a forgotten lab cheap. The VMs stay allocated until deleted (disks still bill).
// Both VM passwords come from secure parameters; there are no defaults.
targetScope = 'resourceGroup'

param location string = resourceGroup().location

@minLength(3)
@maxLength(10)
@description('Prefix for resource names, for example lab.')
param labName string = 'lab'

@description('Active Directory forest name to create, for example contoso.local or lab.contoso.com.')
param domainName string = 'contoso.local'

@description('NetBIOS name of the domain. Max 15 characters.')
@maxLength(15)
param domainNetbiosName string = 'CONTOSO'

param adminUsername string = 'labadmin'

@secure()
@minLength(12)
@description('Local administrator and domain administrator password.')
param adminPassword string

@secure()
@minLength(12)
@description('Directory Services Restore Mode password. Keep it different from adminPassword.')
param dsrmPassword string

@description('Source range allowed to RDP, CIDR, for example 203.0.113.10/32. No default on purpose.')
param rdpSourceRange string

param vmSize string = 'Standard_B2ms'

@description('Daily shutdown time, HHmm.')
param shutdownTime string = '1900'
param shutdownTimeZone string = 'UTC'

param vnetAddressPrefix string = '10.100.0.0/16'
param subnetAddressPrefix string = '10.100.1.0/24'
@description('Static IP of the DC inside subnetAddressPrefix (first usable address is .4).')
param dcPrivateIp string = '10.100.1.4'

param tags object = {
  purpose: 'training'
  lifetime: 'temporary'
}

var dcName = '${labName}-dc1'
var memberName = '${labName}-srv1'
var image = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${labName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-rdp-from-source'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: rdpSourceRange
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'deny-internet-rdp'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${labName}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressPrefix ]
    }
    dhcpOptions: {
      dnsServers: [ dcPrivateIp ]
    }
    subnets: [
      {
        name: 'snet-servers'
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: { id: nsg.id }
        }
      }
    ]
  }
}

var subnetId = '${vnet.id}/subnets/snet-servers'

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for name in [ dcName, memberName ]: {
    name: 'pip-${name}'
    location: location
    tags: tags
    sku: { name: 'Standard' }
    properties: { publicIPAllocationMethod: 'Static' }
  }
]

resource dcNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${dcName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: dcPrivateIp
          publicIPAddress: { id: pip[0].id }
        }
      }
    ]
  }
}

resource memberNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${memberName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pip[1].id }
        }
      }
    ]
  }
}

resource dc 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: dcName
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: dcName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: image
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: dcNic.id, properties: { deleteOption: 'Delete' } }
      ]
    }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}

// Installs AD DS and creates the forest. The DSRM password is passed as a protected parameter, so it is
// not stored in the VM resource or the deployment history in clear text.
resource promote 'Microsoft.Compute/virtualMachines/runCommands@2025-04-01' = {
  parent: dc
  name: 'promote-forest'
  location: location
  properties: {
    asyncExecution: false
    timeoutInSeconds: 1800
    source: {
      script: '''
param([string]$DomainName, [string]$NetbiosName, [string]$DSRM)
$ErrorActionPreference = 'Stop'
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
Install-ADDSForest -DomainName $DomainName -DomainNetbiosName $NetbiosName `
  -SafeModeAdministratorPassword (ConvertTo-SecureString $DSRM -AsPlainText -Force) `
  -InstallDns -NoRebootOnCompletion -Force
# Reboot after the command returns so the extension reports success.
shutdown.exe /r /t 60 /c "AD DS promotion"
'''
    }
    parameters: [
      { name: 'DomainName', value: domainName }
      { name: 'NetbiosName', value: domainNetbiosName }
    ]
    protectedParameters: [
      { name: 'DSRM', value: dsrmPassword }
    ]
  }
}

resource member 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: memberName
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: memberName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: image
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
      dataDisks: [
        {
          // Separate data disk for file share / File Sync style exercises.
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 32
          deleteOption: 'Delete'
          managedDisk: { storageAccountType: 'StandardSSD_LRS' }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        { id: memberNic.id, properties: { deleteOption: 'Delete' } }
      ]
    }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
  dependsOn: [ promote ]
}

// The DC restarts about a minute after the Run Command returns; the join retries until the domain answers.
resource join 'Microsoft.Compute/virtualMachines/extensions@2025-04-01' = {
  parent: member
  name: 'domain-join'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      User: '${domainName}\\${adminUsername}'
      Restart: true
      Options: 3
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
}

resource shutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = [
  for (name, i) in [ dcName, memberName ]: {
    name: 'shutdown-computevm-${name}'
    location: location
    tags: tags
    properties: {
      status: 'Enabled'
      taskType: 'ComputeVmShutdownTask'
      dailyRecurrence: { time: shutdownTime }
      timeZoneId: shutdownTimeZone
      targetResourceId: i == 0 ? dc.id : member.id
      notificationSettings: { status: 'Disabled' }
    }
  }
]

output domainName string = domainName
output dcPublicIp string = pip[0].properties.ipAddress
output memberPublicIp string = pip[1].properties.ipAddress
output rdpUser string = '${domainNetbiosName}\\${adminUsername}'

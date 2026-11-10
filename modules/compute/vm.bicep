
@description('Azure region.')
param location string

@description('Windows computer name.')
param computerName string

@description('Windows VM name.')
param vmName string

@description('Local administrator username.')
param adminUsername string

@secure()
@description('Local administrator password.')
param vmAdminPassword string

@description('VM size.')
param vmSize string

@description('Resource tags.')
param tags object

@description('Virtual network name in this resource group.')
param vnetName string

@description('Subnet name in the virtual network.')
param subnetName string

@description('Network interface name.')
param nicName string

@description('Private IP allocation method.')
@allowed([
  'Dynamic'
  'Static'
])
param privateIpAllocationMethod string

@description('Marketplace image publisher.')
param imagePublisher string

@description('Marketplace image offer.')
param imageOffer string

@description('Marketplace image SKU.')
param imageSku string

@description('Marketplace image version.')
param imageVersion string

@description('Managed OS disk storage account type.')
param osDiskStorageAccountType string

@description('OS disk create option.')
@allowed([
  'FromImage'
])
param osDiskCreateOption string

@description('OS disk size in GB; null uses the image default.')
param osDiskSizeGB int

@description('Enable boot diagnostics.')
param enableBootDiagnostics bool

// Existing VNet and subnet created by the networking module.
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: vnet
  name: subnetName
}

// Always manage the NIC through Bicep.
// Azure creates it when missing and reconciles it when already present.
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: '${nicName}-ipconfig'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: privateIpAllocationMethod
        }
      }
    ]
  }
}

// Windows Virtual Machine.
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        createOption: osDiskCreateOption
        managedDisk: {
          storageAccountType: osDiskStorageAccountType
        }
        diskSizeGB: osDiskSizeGB > 0 ? osDiskSizeGB : null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: enableBootDiagnostics
      }
    }
  }
}

output vmId string = vm.id
output vmNameOut string = vm.name
output networkInterfaceId string = nic.id

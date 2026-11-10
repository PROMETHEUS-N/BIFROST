
@description('Azure region.')
param location string

@description('Virtual network name.')
param vnetName string

@description('Virtual network CIDR prefixes.')
param addressPrefixes array

@description('Resource tags.')
param tags object

@description('Custom DNS server IP addresses; use an empty array for Azure-provided DNS.')
param dnsServers array

@description('Complete subnet definitions belonging to this VNet.')
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    subnets: subnets
  }
}

output vnetId string = vnet.id
output vnetNameOut string = vnet.name

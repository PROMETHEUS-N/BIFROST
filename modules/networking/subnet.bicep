@description('Existing virtual network in the current resource group.')
param vnetName string

@description('Subnet name.')
param subnetName string

@description('Subnet CIDR prefix.')
param addressPrefix string

@description('NSG name to associate, or empty string for no NSG.')
param networkSecurityGroupName string

@description('Route table name to associate, or empty string for no route table.')
param routeTableName string

@description('Subnet service endpoints configuration.')
param serviceEndpoints array

@description('Private endpoint network policy setting.')
@allowed([
  'Enabled'
  'Disabled'
  'NetworkSecurityGroupEnabled'
  'RouteTableEnabled'
])
param privateEndpointNetworkPolicies string

@description('Private link service network policy setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param privateLinkServiceNetworkPolicies string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: addressPrefix
    serviceEndpoints: serviceEndpoints
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
    networkSecurityGroup: !empty(networkSecurityGroupName) ? {
      id: resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
    } : null
    routeTable: !empty(routeTableName) ? {
      id: resourceId('Microsoft.Network/routeTables', routeTableName)
    } : null
  }
}

output subnetId string = subnet.id
output subnetNameOut string = subnet.name

@description('Azure region.')
param location string

@description('Network security group name.')
param nsgName string

@description('Security rule objects matching Azure NSG security rule properties.')
param securityRules array

@description('Resource tags.')
param tags object

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      for rule in securityRules: {
        name: rule.name
        properties: {
          description: contains(rule, 'description') ? rule.description : null
          protocol: rule.protocol
          sourcePortRange: rule.sourcePortRange
          destinationPortRange: rule.destinationPortRange
          sourceAddressPrefix: rule.sourceAddressPrefix
          destinationAddressPrefix: rule.destinationAddressPrefix
          access: rule.access
          priority: rule.priority
          direction: rule.direction
        }
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgNameOut string = nsg.name

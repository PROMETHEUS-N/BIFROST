@description('Route table name.')
param routeTableName string

@description('Azure region.')
param location string

@description('Disable BGP route propagation.')
param disableBgpRoutePropagation bool

@description('Route objects matching Azure route properties.')
param routes array

@description('Resource tags.')
param tags object

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      for route in routes: {
        name: route.name
        properties: {
          addressPrefix: route.addressPrefix
          nextHopType: route.nextHopType
          nextHopIpAddress: contains(route, 'nextHopIpAddress') ? route.nextHopIpAddress : null
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
output routeTableNameOut string = routeTable.name

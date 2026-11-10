@description('Azure region.')
param location string

@description('Globally unique SQL logical server name.')
param serverName string

@description('SQL database name.')
param databaseName string

@description('SQL administrator login.')
param administratorLogin string

@secure()
@description('SQL administrator password.')
param administratorLoginPassword string

@description('SQL Server version.')
param sqlServerVersion string

@description('Database SKU name.')
param databaseSkuName string

@description('Database SKU tier.')
param databaseSkuTier string

@description('Database SKU capacity.')
param databaseCapacity int

@description('Maximum database size in bytes.')
param databaseMaxSizeBytes int

@description('Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

@description('Minimum TLS version.')
param minimumTlsVersion string

@description('Resource tags.')
param tags object

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: sqlServerVersion
    publicNetworkAccess: publicNetworkAccess
    minimalTlsVersion: minimumTlsVersion
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    capacity: databaseCapacity
  }
  properties: {
    maxSizeBytes: databaseMaxSizeBytes
  }
}

output sqlServerId string = sqlServer.id
output sqlServerNameOut string = sqlServer.name
output sqlDatabaseId string = sqlDatabase.id
output sqlDatabaseNameOut string = sqlDatabase.name

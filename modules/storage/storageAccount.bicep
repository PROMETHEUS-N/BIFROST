
@description('Globally unique storage account name: 3-24 lowercase letters and numbers only.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Storage account SKU.')
param skuName string

@description('Storage account kind.')
param kind string

@description('Blob access tier.')
param accessTier string

@description('Minimum TLS version.')
param minimumTlsVersion string

@description('Require HTTPS for data-plane traffic.')
param supportsHttpsTrafficOnly bool

@description('Allow anonymous blob access.')
param allowBlobPublicAccess bool

@description('Allow Shared Key authorization.')
param allowSharedKeyAccess bool

@description('Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

@description('Container names to create.')
param containerNames array

@description('Blob service name (normally default).')
param blobServiceName string

@description('Container public access level.')
@allowed([
  'None'
  'Blob'
  'Container'
])
param containerPublicAccess string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${substring(storageAccountName,0,min(length(storageAccountName), 19))}${substring(uniqueString(subscription().id, resourceGroup().id, storageAccountName), 0, 5)}'
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    publicNetworkAccess: publicNetworkAccess
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: blobServiceName
  properties: {
    deleteRetentionPolicy: {
      enabled: false
      allowPermanentDelete: false
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for containerName in containerNames: {
    parent: blobService
    name: containerName
    properties: {
      publicAccess: containerPublicAccess
      defaultEncryptionScope: '$account-encryption-key'
      denyEncryptionScopeOverride: false
    }
  }
]

output storageAccountId string = storageAccount.id
output storageAccountNameOut string = storageAccount.name
output containerNamesOut array = containerNames

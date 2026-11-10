@description('Globally unique Key Vault name: 3-24 characters, letters, numbers and hyphens; starts with a letter.')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Azure region.')
param location string

@description('Microsoft Entra tenant ID.')
param tenantId string

@description('Key Vault SKU name.')
@allowed([
  'standard'
  'premium'
])
param skuName string

@description('Key Vault SKU family.')
@allowed([
  'A'
])
param skuFamily string

@description('Use Azure RBAC for data-plane authorization.')
param enableRbacAuthorization bool

@description('Enable purge protection.')
param enablePurgeProtection bool

@description('Soft-delete retention in days.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int

@description('Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

@description('Resource tags.')
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${substring(keyVaultName, 0, min(length(keyVaultName), 15))}${substring(uniqueString(subscription().id, resourceGroup().id, keyVaultName), 0, 5)}'
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: enableRbacAuthorization
    enablePurgeProtection: enablePurgeProtection
    softDeleteRetentionInDays: softDeleteRetentionInDays
    publicNetworkAccess: publicNetworkAccess
    sku: {
      name: skuName
      family: skuFamily
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultNameOut string = keyVault.name

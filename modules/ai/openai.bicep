@description('Azure OpenAI account name. Must be globally available in the selected Azure region.')
@minLength(2)
@maxLength(64)
param accountName string

@description('Azure region.')
param location string

@description('Azure OpenAI SKU name.')
param skuName string

@description('Custom subdomain name for the Azure OpenAI endpoint; keep stable after creation.')
@minLength(2)
@maxLength(64)
param customSubDomainName string

@description('Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

@description('Resource tags.')
param tags object

resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${substring(accountName, 0, min(length(accountName), 20))}${substring(uniqueString(subscription().id, resourceGroup().id, accountName), 0, 5)}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
  }
  tags: tags
}

output accountId string = openAiService.id
output accountName string = openAiService.name
output location string = openAiService.location

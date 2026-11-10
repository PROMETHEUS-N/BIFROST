targetScope = 'subscription'
param rgname string 
param location string
param tags object


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgname
  location: location
  tags: tags
}















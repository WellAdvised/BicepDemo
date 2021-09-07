targetScope = 'subscription'

@description('Used for naming of various resources, commonly matches name of client, f.x. Vettvangur.')
param projectName string

@description('AAD Object id / SID of Sql Admin security group.')
param cloudSecurityGroupObjectId string

@description('Azure Web Resource Group Name')
param rgWebName string = 'web-rg'
@description('Azure Database/Storage Resource Group Name')
param rgDataName string = 'data-rg'
@description('Azure Resource Group Name')
param rgName string = '${projectName}-rg'

@description('VNet address prefix.')
param addressPrefix string = '172.28.29.0/24'
param storageAccountName string = toLower('${projectName}-web')
param keyVaultName string = '${projectName}-web'

@description('Array of single ip address hosts allowed to access firewalled resources')
param whitelistedIPs array = [
  {
    name: 'One.One'
    host: '1.0.0.1'
  }
]

var keyVaultSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'

resource rgWeb 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgWebName
  location: deployment().location
  properties: {}
}

resource rgData 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgDataName
  location: deployment().location
  properties: {}
}

// VNet, LogAnalytics, other
resource rgOps 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: deployment().location
  tags: {
    'WellAdvised.cloud': 'ops-rg'
  }
  properties: {}
}

module waWebRg './resources/mainRg.bicep' = {
  name: 'WellAdvised-WebDeployment-ResourceGroup'
  scope: rgOps
  params: {
    projectName: projectName
    cloudSecurityGroupObjectId: cloudSecurityGroupObjectId
    sqlServerName: '${projectName}web'
    addressPrefix: addressPrefix
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
    whitelistedIPs: whitelistedIPs
    rgData: rgDataName
    rgWeb: rgWebName
  }
}

resource webIdentityRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().subscriptionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUser)
    principalId: waWebRg.outputs.webIdentity
  }
}

resource webIdentityDevRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().subscriptionId, waWebRg.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUser)
    principalId: waWebRg.outputs.webIdentityDev
  }
}

resource webIdentityStagingRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().subscriptionId, projectName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUser)
    principalId: waWebRg.outputs.webIdentityStaging
  }
}

resource webIdentityPreProductionRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().subscriptionId, rgDataName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUser)
    principalId: waWebRg.outputs.webIdentityPreProduction
  }
}

resource auditLog 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'auditlog'
  properties: {
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
    ]
    workspaceId: waWebRg.outputs.auditLog
  }
}

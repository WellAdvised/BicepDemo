param projectName string
param sqlServerName string
param cloudSecurityGroupObjectId string
param addressPrefix string
param storageAccountName string
param keyVaultName string
param rgData string
param rgWeb string

@description('Location for all resources.')
param location string = resourceGroup().location
param whitelistedIPs array

var vnetName = 'web-vnet'
var vnetAddressPrefix = addressPrefix
var subnetAppServicePrefix = '${substring(addressPrefix, 0, lastIndexOf(addressPrefix, '.'))}.160/27'
var appServiceSubnetName = 'appService'
var httpRequestLogAnalyticsWorkspacename = 'httpreq-log'
var auditLogWorkspaceName = 'audit-log'
var httpRequestLogRetention = 90
var auditLogRetention = 730 // Max
var ipRules = [for ip in whitelistedIPs: {
  value: ip.host
}]

resource httpRequestLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: httpRequestLogAnalyticsWorkspacename
  location: location
  tags: {
    'WellAdvised.cloud': 'httpreqlog'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: httpRequestLogRetention
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource auditLogWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: auditLogWorkspaceName
  location: location
  tags: {
    'WellAdvised.cloud': 'auditlog'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: auditLogRetention
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}
output auditLog string = auditLogWorkspace.id

resource vnet 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

// Can't seem to reference child resource so we split these up
resource appServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: appServiceSubnetName
  parent: vnet
  properties: {
    addressPrefix: subnetAppServicePrefix
    serviceEndpoints: [
      {
        service: 'Microsoft.Sql'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.KeyVault'
        locations: [
          location
        ]
      }
    ]
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
  }
}

module data './resources/data.bicep' = {
  name: 'WellAdvised-ResourceGroup-DataDeployment'
  scope: resourceGroup(rgData)
  params: {
    projectName: projectName
    sqlServerName: sqlServerName
    cloudSecurityGroupObjectId: cloudSecurityGroupObjectId
    whitelistedIPs: whitelistedIPs
    subnet: appServiceSubnet.id
    storageAccountName: storageAccountName
  }
}

module keyVaults './resources/keyVaults.bicep' = {
  name: 'WellAdvised-ResourceGroup-KeyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    ipRules: ipRules
    appServiceSubnetId: appServiceSubnet.id
    auditWorkspace: auditLogWorkspace.id
  }
}

module appService './resources/appService.bicep' = {
  name: 'WellAdvised-ResourceGroup-WebDeployment'
  scope: resourceGroup(rgWeb)
  params: {
    projectName: projectName
    whitelistedIPs: whitelistedIPs
    subnet: appServiceSubnet.id
    workspace: httpRequestLogAnalyticsWorkspace.id
    auditWorkspace: auditLogWorkspace.id
  }
}

output webIdentity string = appService.outputs.webIdentity
output webIdentityDev string = appService.outputs.webIdentityDev
output webIdentityStaging string = appService.outputs.webIdentityStaging
output webIdentityPreProduction string = appService.outputs.webIdentityPreProduction

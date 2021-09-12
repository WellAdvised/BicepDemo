param projectName string
param sqlServerName string
param cloudSecurityGroupObjectId string
param subnet string
param storageAccountName string

@description('Location for all resources.')
param location string = resourceGroup().location
param whitelistedIPs array

var databaseName = 'Umbraco-Production'
var cloudSecurityGroupName = 'WebApp Sql Admins'
var cloudSecurityGroupObjectId_var = cloudSecurityGroupObjectId

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'None'
    }
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }

  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: 36
      }
      isVersioningEnabled: true
      changeFeed: {
        enabled: true
      }
      restorePolicy: {
        enabled: true
        days: 35
      }
      containerDeleteRetentionPolicy: {
        enabled: true
        days: 30
      }
    }

    resource storageAccountName_default_imagecache 'containers@2021-01-01' = {
      name: 'imagecache'
      properties: {
        publicAccess: 'Blob'
      }
    }
    resource storageAccountName_default_media 'containers@2021-01-01' = {
      name: 'media'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: toLower(sqlServerName)
  location: location
  tags: {}
  properties: {
    administratorLogin: projectName
    administratorLoginPassword: '${uniqueString(resourceGroup().id)}${uniqueString(location)}${subscription().subscriptionId}'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }

  resource sqlServer_ActiveDirectory 'administrators@2020-08-01-preview' = {
    name: 'ActiveDirectory'
    properties: {
      administratorType: 'ActiveDirectory'
      login: cloudSecurityGroupName
      sid: cloudSecurityGroupObjectId_var
      tenantId: subscription().tenantId
    }
  }

  resource sqlServerName_Default 'azureADOnlyAuthentications@2020-08-01-preview' = {
    name: 'Default'
    properties: {
      azureADOnlyAuthentication: true
    }
    dependsOn: [
      sqlServer_ActiveDirectory
    ]
  }

  resource productionDatabase 'databases@2019-06-01-preview' = {
    name: databaseName
    location: location
    sku: {
      name: 'Standard'
      tier: 'Standard'
      capacity: 20
    }
    properties: {
      collation: 'SQL_Latin1_General_CP1_CI_AS'
      maxSizeBytes: 268435456000
    }

    resource backupRetentionPolicy 'backupShortTermRetentionPolicies@2020-08-01-preview' = {
      name: 'default'
      properties: {
        retentionDays: 35
      }
    }
  }

  resource sqlServer_firewallRules 'firewallRules@2020-08-01-preview' = [for (item, index) in whitelistedIPs: {
    name: '${item.name} - ${index}'
    properties: {
      startIpAddress: item.host
      endIpAddress: item.host
    }
  }]

  resource vnetrules 'virtualNetworkRules@2021-02-01-preview' = {
    name: 'appServiceRule'
    properties: {
      virtualNetworkSubnetId: subnet
    }
  }
}

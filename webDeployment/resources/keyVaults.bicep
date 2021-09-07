param keyVaultName string
param ipRules array
param appServiceSubnetId string
param auditWorkspace string

resource keyVault 'Microsoft.KeyVault/vaults@2020-04-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: ipRules
      virtualNetworkRules: [
        {
          id: appServiceSubnetId
        }
      ]
    }
    enableRbacAuthorization: true
  }
}

resource keyVaultStaging 'Microsoft.KeyVault/vaults@2020-04-01-preview' = {
  name: '${keyVaultName}-Staging'
  dependsOn: [
    keyVault // Was getting conflicts when using default parallel deploy
  ]
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: ipRules
      virtualNetworkRules: [
        {
          id: appServiceSubnetId
        }
      ]
    }
    enableRbacAuthorization: true
  }
}
resource keyVaultDev 'Microsoft.KeyVault/vaults@2020-04-01-preview' = {
  name: '${keyVaultName}-Dev'
  dependsOn: [
    keyVaultStaging // Was getting conflicts when using default parallel deploy
  ]
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: ipRules
      virtualNetworkRules: [
        {
          id: appServiceSubnetId
        }
      ]
    }
    enableRbacAuthorization: true
  }
}

resource keyVaultDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'auditlog'
  scope: keyVault
  properties: {
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    workspaceId: auditWorkspace
  }
}

resource keyVaultDevDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'auditlog'
  scope: keyVaultDev
  properties: {
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    workspaceId: auditWorkspace
  }
}

resource keyVaultStagingDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'auditlog'
  scope: keyVaultStaging
  properties: {
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    workspaceId: auditWorkspace
  }
}

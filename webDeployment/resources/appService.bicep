param projectName string
param subnet string
param workspace string

@description('Location for all resources.')
param location string = resourceGroup().location
param whitelistedIPs array

var websitename = '${projectName}-umbraco'
var appServicePlanName = '${projectName}-plan'
var ipSecurityRestrictions = [for (ip, i) in whitelistedIPs: {
  ipAddress: '${ip.host}/32'
  action: 'Allow'
  tag: 'Default'
  priority: (50 + (10 * i))
  name: ip.name
}]

resource appServicePlan 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v3'
    capacity: 1
  }
  tags: {}
}

resource website 'Microsoft.Web/sites@2019-08-01' = {
  name: websitename
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      use32BitWorkerProcess: false
      http20Enabled: true
      ftpsState: 'FtpsOnly'
      scmIpSecurityRestrictions: ipSecurityRestrictions
    }
  }

  resource websitename_virtualNetwork 'networkConfig@2019-08-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: subnet
      swiftSupported: true
    }
  }

  resource iisCompression 'siteextensions@2018-11-01' = {
    name: 'IIS.Compression.SiteExtension'
  }
}

resource websiteDev 'Microsoft.Web/sites/slots@2018-11-01' = {
  name: '${website.name}/Dev'
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: false
      use32BitWorkerProcess: false
      http20Enabled: true
      ftpsState: 'FtpsOnly'
      ipSecurityRestrictions: ipSecurityRestrictions
      scmIpSecurityRestrictionsUseMain: true
    }
  }

  resource websitename_Staging_virtualNetwork 'networkConfig@2019-08-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: subnet
      swiftSupported: true
    }
  }
}

resource websiteStaging 'Microsoft.Web/sites/slots@2018-11-01' = {
  name: '${website.name}/Staging'
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      // Allow sql serverless savings
      alwaysOn: false
      use32BitWorkerProcess: false
      http20Enabled: true
      ftpsState: 'FtpsOnly'
      ipSecurityRestrictions: ipSecurityRestrictions
      scmIpSecurityRestrictionsUseMain: true
    }
  }

  resource websitename_Staging_virtualNetwork 'networkConfig@2019-08-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: subnet
      swiftSupported: true
    }
  }

  resource iisCompression 'siteextensions@2018-11-01' = {
    name: 'IIS.Compression.SiteExtension'
  }
}

resource websitename_PreProduction 'Microsoft.Web/sites/slots@2018-11-01' = {
  name: '${website.name}/PreProduction'
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      // Allow sql serverless savings
      alwaysOn: false
      use32BitWorkerProcess: false
      http20Enabled: true
      ftpsState: 'FtpsOnly'
      ipSecurityRestrictions: ipSecurityRestrictions
      scmIpSecurityRestrictionsUseMain: true
    }
  }

  resource websitename_Staging_virtualNetwork 'networkConfig@2019-08-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: subnet
      swiftSupported: true
    }
  }
}

resource microsoft_insights_components_websitename 'microsoft.insights/components@2020-02-02-preview' = {
  name: websitename
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace
  }
}

resource appServiceLogs 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'appServiceLogs'
  scope: website
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
    ]
    workspaceId: workspace
  }
}
resource appServiceDevLogs 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'appServiceLogs'
  scope: websiteDev
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
    ]
    workspaceId: workspace
  }
}
resource appServiceStagingLogs 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'appServiceLogs'
  scope: websiteStaging
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
    ]
    workspaceId: workspace
  }
}

output webIdentity string = website.identity.principalId
output webIdentityDev string = websiteDev.identity.principalId
output webIdentityStaging string = websiteStaging.identity.principalId
output webIdentityPreProduction string = websitename_PreProduction.identity.principalId

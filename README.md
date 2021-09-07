# Azure Infrastructure as Code

New-AzSubscriptionDeployment `
  -Name 'WellAdvised-WebDeployment' `
  -Location $location `
  -TemplateFile '.\webDeployment\main.bicep' `
  -projectName $ProjectName `
  -cloudSecurityGroupObjectId $sqlAdminsObjectId

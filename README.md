# Azure Infrastructure as Code

# How to run

Grab your users object id
$sqlAdminsObjectId = (Get-AzContext).Account.ExtendedProperties.HomeAccountId.Split('.')[0]

New-AzSubscriptionDeployment `
  -Name 'WellAdvised-WebDeployment' `
  -Location $location `
  -TemplateFile '.\webDeployment\main.bicep' `
  -projectName $ProjectName `
  -cloudSecurityGroupObjectId $sqlAdminsObjectId `
  -Confirm

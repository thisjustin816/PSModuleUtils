$Name = 'PSModuleUtils'

Import-Module -Name "$PSScriptRoot/src/$Name.psm1" -Force
Publish-PSModule -Name $Name -Confirm:(!$env:GITHUB_ACTIONS)

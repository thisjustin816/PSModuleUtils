$Name = 'PSModuleUtils'
$Version = '0.0.1'

Import-Module -Name "$PSScriptRoot/src/PSModuleUtils.psm1" -Force

Build-PSModule -Name $Name -Version $Version -FixScriptAnalyzer
Test-PSModule -Name $Name
Publish-PSModule -Name $Name
$BuildPSModule = @{
    Name        = 'PSModuleUtils'
    Version     = '1.8.0-preview2'
    Guid        = '3c63c38f-c32c-4837-a6fa-0b456f4099ce'
    Description = 'A module with helper functions to build and publish PowerShell modules to the PSGallery.'
    Tags        = ('PSEdition_Desktop', 'PSEdition_Core', 'Windows')
}

Push-Location -Path $PSScriptRoot
Import-Module -Name "$PSScriptRoot/src/$($BuildPSModule['Name']).psm1" -Force
if (!$env:GITHUB_ACTIONS) {
    Invoke-PSModuleAnalyzer -Fix
}
Build-PSModule @BuildPSModule
Test-PSModule -Name $BuildPSModule['Name']
Pop-Location

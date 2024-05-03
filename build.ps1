$BuildPSModule = @{
    Name        = 'PSModuleUtils'
    Version     = '0.0.2'
    Description = 'A module with helper functions to build and publish PowerShell modules to the PSGallery.'
    Tags        = ('PSEdition_Desktop', 'PSEdition_Core', 'Windows')
}

Push-Location -Path $PSScriptRoot
Import-Module -Name "$PSScriptRoot/src/$($BuildPSModule['Name']).psm1" -Force
Build-PSModule @BuildPSModule
Test-PSModule -Name $BuildPSModule['Name']
Pop-Location

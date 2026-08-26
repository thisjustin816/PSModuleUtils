@{
    RootModule           = 'PSModuleUtils.psm1'
    ModuleVersion        = '4.2.0'
    GUID                 = '3c63c38f-c32c-4837-a6fa-0b456f4099ce'
    Author               = ''
    CompanyName          = ''
    Copyright            = ''
    Description          = 'A module with helper functions to build and publish PowerShell modules to the PSGallery.'
    PowerShellVersion    = '7.4'
    CompatiblePSEditions = @('Core')
    FunctionsToExport    = @()
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    RequiredModules      = @(
        @{ ModuleName = 'ModuleBuilder'; ModuleVersion = '3.2.18'; MaximumVersion = '3.999.999' }
        @{ ModuleName = 'Metadata'; ModuleVersion = '1.5.0'; MaximumVersion = '1.999.999' }
        @{ ModuleName = 'JBUtils'; ModuleVersion = '1.1.0'; MaximumVersion = '1.999.999' }
        @{ ModuleName = 'Pester'; ModuleVersion = '5.0'; MaximumVersion = '5.999.999' }
        @{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.20.0'; MaximumVersion = '1.999.999' }
        @{ ModuleName = 'Microsoft.PowerShell.PSResourceGet'; ModuleVersion = '1.0.0' }
    )
    PrivateData          = @{
        PSData = @{
            Tags         = @('PSEdition_Core', 'Windows', 'Linux', 'macOS')
            ProjectUri   = ''
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = ''
            Prerelease   = ''
        }
    }
}

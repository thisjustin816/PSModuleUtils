Describe 'Integration Tests' -Tag 'Integration' {
    BeforeAll {
        Import-Module -Name "$PSScriptRoot/../PSModuleUtils.psm1" -Force
    }

    It 'should build a versioned module' {
        $BuildPSModule = @{
            Name    = 'PSModuleUtils'
            Version = '1.0.0-pester'
        }

        Build-PSModule @BuildPSModule -SourceDirectory "$PSScriptRoot/.." -OutputDirectory "$TestDrive/out"

        "$TestDrive/out/PSModuleUtils/1.0.0-pester/PSModuleUtils.psd1" | Should -Exist
        { Import-Module -Name "$TestDrive/out/PSModuleUtils/1.0.0-pester/PSModuleUtils.psd1" -Force } |
            Should -Not -Throw
    }
}

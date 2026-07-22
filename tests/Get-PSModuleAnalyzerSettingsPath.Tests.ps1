# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Get-PSModuleAnalyzerSettingsPath.ps1
    }

    It 'should resolve the source layout (Settings is one level up)' {
        Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot "$PSScriptRoot/../src/Public" | Should -Exist
    }

    It 'should resolve the built layout (Settings is a direct sibling)' {
        $builtRoot = Join-Path -Path $TestDrive -ChildPath 'built'
        $settingsDirectory = Join-Path -Path $builtRoot -ChildPath 'Settings'
        $null = New-Item -ItemType Directory -Path $settingsDirectory -Force
        Copy-Item -Path "$PSScriptRoot/../src/Settings/PSScriptAnalyzerSettings.psd1" `
            -Destination $settingsDirectory

        Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot $builtRoot | Should -Exist
    }

    It 'should return nothing when neither candidate exists' {
        Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot $TestDrive | Should -BeNullOrEmpty
    }
}

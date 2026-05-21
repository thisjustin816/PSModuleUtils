# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/Invoke-PSModuleAnalyzer.ps1
        $cleanFile = Join-Path -Path $TestDrive -ChildPath 'Clean.ps1'
        "function Get-Clean { 'ok' }" | Set-Content -Path $cleanFile -Encoding utf8
    }

    It 'should not throw on a clean source directory in fix mode' {
        { Invoke-PSModuleAnalyzer -SourceDirectory $TestDrive -Fix } | Should -Not -Throw
    }

    It 'should accept a custom settings file path' {
        $settings = Resolve-Path -Path "$PSScriptRoot/../private/PSScriptAnalyzerSettings.psd1"
        { Invoke-PSModuleAnalyzer -SourceDirectory $TestDrive -Settings $settings -Fix } | Should -Not -Throw
    }
}

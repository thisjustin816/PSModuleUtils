# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Get-PSModuleAnalyzerTargetSettings.ps1
        $script:SettingsPath = "$PSScriptRoot/../src/Settings/PSScriptAnalyzerSettings.psd1"
    }

    It 'should retarget every compatibility rule from a settings path' {
        $settings = Get-PSModuleAnalyzerTargetSettings -Settings $script:SettingsPath -TargetVersion '7.0'

        $settings.Rules.PSUseCompatibleSyntax.TargetVersions | Should -Be @('7.0')
        $settings.Rules.PSUseCompatibleCommands.TargetProfiles | Should -Be @('win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core')
        $settings.Rules.PSUseCompatibleTypes.TargetProfiles | Should -Be @('win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core')
        $settings.Rules.PSUseCompatibleCmdlets.compatibility | Should -Be @('core-6.1.0-windows')
        $settings.Rules.PSAvoidOverwritingBuiltInCmdlets.PowerShellVersion | Should -Be @('core-6.1.0-windows')
    }

    It 'should target Windows PowerShell when asked for 5.1' {
        $settings = Get-PSModuleAnalyzerTargetSettings -Settings $script:SettingsPath -TargetVersion '5.1'

        $settings.Rules.PSUseCompatibleSyntax.TargetVersions | Should -Be @('5.1')
        $settings.Rules.PSUseCompatibleCmdlets.compatibility | Should -Be @('desktop-5.1.14393.206-windows')
    }

    It 'should accept several versions at once' {
        $settings = Get-PSModuleAnalyzerTargetSettings -Settings $script:SettingsPath -TargetVersion '5.1', '7.0'

        $settings.Rules.PSUseCompatibleSyntax.TargetVersions | Should -HaveCount 2
        $settings.Rules.PSUseCompatibleCommands.TargetProfiles | Should -HaveCount 2
    }

    It 'should keep rule keys the target does not own' {
        $settings = Get-PSModuleAnalyzerTargetSettings -Settings $script:SettingsPath -TargetVersion '7.0'

        $settings.Rules.PSUseCompatibleCommands.IgnoreCommands | Should -Be @('Invoke-Pester')
        $settings.Rules.PSAvoidLongLines.MaximumLineLength | Should -Be 120
        $settings.ExcludeRules | Should -Contain 'PSAvoidUsingWriteHost'
    }

    It 'should accept a settings hashtable' {
        $source = Import-PowerShellDataFile -Path $script:SettingsPath

        $settings = Get-PSModuleAnalyzerTargetSettings -Settings $source -TargetVersion '7.0'

        $settings.Rules.PSUseCompatibleSyntax.TargetVersions | Should -Be @('7.0')
    }

    It 'should not modify the settings hashtable it was given' {
        $source = Import-PowerShellDataFile -Path $script:SettingsPath
        $before = $source.Rules.PSUseCompatibleSyntax.TargetVersions -join ','

        $null = Get-PSModuleAnalyzerTargetSettings -Settings $source -TargetVersion '7.0'

        ($source.Rules.PSUseCompatibleSyntax.TargetVersions -join ',') | Should -Be $before
    }

    It 'should add a compatibility rule that the settings omit' {
        $settings = Get-PSModuleAnalyzerTargetSettings -Settings @{} -TargetVersion '7.0'

        $settings.Rules.PSUseCompatibleSyntax.TargetVersions | Should -Be @('7.0')
    }

    It 'should reject a version it has no mapping for' {
        { Get-PSModuleAnalyzerTargetSettings -Settings @{} -TargetVersion '6.0' } | Should -Throw
    }
}

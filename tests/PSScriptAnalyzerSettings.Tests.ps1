# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'PSScriptAnalyzer settings' -Tag 'Unit' {
    BeforeAll {
        $script:settingsPath = "$PSScriptRoot/../src/Settings/PSScriptAnalyzerSettings.psd1"
        $script:settings = Import-PowerShellDataFile -Path $script:settingsPath
        $script:windowsCompatibilityProfiles = @(
            'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
        )
        $script:legacyCompatibilityProfiles = @(
            'desktop-5.1.14393.206-windows'
            'core-6.1.0-windows'
        )
    }

    It 'should target Windows PowerShell and PowerShell Core with the legacy compatibility rules' {
        ($script:settings.Rules.PSAvoidOverwritingBuiltInCmdlets.PowerShellVersion -join '|') |
            Should -BeExactly ($script:legacyCompatibilityProfiles -join '|')
        ($script:settings.Rules.PSUseCompatibleCmdlets.compatibility -join '|') |
            Should -BeExactly ($script:legacyCompatibilityProfiles -join '|')
    }

    It 'should configure compatible commands with every supported option' {
        $rule = $script:settings.Rules.PSUseCompatibleCommands

        $rule.Enable | Should -BeTrue
        ($rule.TargetProfiles -join '|') | Should -BeExactly ($script:windowsCompatibilityProfiles -join '|')
        ($rule.IgnoreCommands -join '|') | Should -BeExactly 'Invoke-Pester'
    }

    It 'should configure compatible types with every supported option' {
        $rule = $script:settings.Rules.PSUseCompatibleTypes

        $rule.Enable | Should -BeTrue
        ($rule.TargetProfiles -join '|') | Should -BeExactly ($script:windowsCompatibilityProfiles -join '|')
        @($rule.IgnoreTypes).Count | Should -Be 0
    }

    It 'should expose constrained language configuration without enabling it by default' {
        $rule = $script:settings.Rules.PSUseConstrainedLanguageMode

        $rule.Enable | Should -BeFalse
        @($rule.IgnoreSignatures).Count | Should -Be 0
    }

    It 'should enable correct command casing' {
        $rule = $script:settings.Rules.PSUseCorrectCasing

        $rule.Enable | Should -BeTrue
        $rule.CheckCommands | Should -BeTrue
        $rule.CheckKeyword | Should -BeTrue
        $rule.CheckOperator | Should -BeTrue
    }

    It 'should allow conventional collective nouns' {
        $rule = $script:settings.Rules.PSUseSingularNouns

        $rule.Enable | Should -BeTrue
        ($rule.NounAllowList -join '|') | Should -BeExactly 'Data|Metadata|Settings|Windows'
    }

    It 'should retain commented examples for path-dependent settings' {
        $settingsContent = Get-Content -Path $script:settingsPath -Raw

        $settingsContent | Should -Match '# CustomRulePath ='
        $settingsContent | Should -Match '# IncludeDefaultRules ='
        $settingsContent | Should -Match '# RecurseCustomRulePath ='
        ([Regex]::Matches($settingsContent, '# ProfileDirPath =')).Count | Should -Be 2
    }
}

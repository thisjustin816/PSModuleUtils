# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Invoke-PSModuleAnalyzerCasingWorkaround' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Invoke-PSModuleAnalyzerCasingWorkaround.ps1
        $script:defaultSettingsPath = (
            Resolve-Path -Path $PSScriptRoot/../src/Settings/PSScriptAnalyzerSettings.psd1
        ).Path
    }

    It 'should analyze casing one file at a time without mutating the caller arguments' {
        $fixtureDir = Join-Path -Path $TestDrive -ChildPath 'CorrectCasingFixture'
        $null = New-Item -ItemType Directory -Path $fixtureDir -Force
        "function Get-First { 'first' }" | Set-Content -Path "$fixtureDir/First.ps1"
        "function Get-Second { 'second' }" | Set-Content -Path "$fixtureDir/Second.psm1"
        'ignored' | Set-Content -Path "$fixtureDir/Ignored.txt"
        $scriptAnalyzerArguments = @{
            Path          = $fixtureDir
            Settings      = $script:defaultSettingsPath
            Recurse       = $true
            Severity      = 'Information'
            EnableExit    = $false
            ReportSummary = $true
            ErrorAction   = 'Stop'
            Fix           = $true
        }
        Mock Invoke-ScriptAnalyzer {}

        Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArguments

        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 2 -ParameterFilter {
            $Settings.IncludeRules -contains 'PSUseCorrectCasing' -and
            $Settings.Rules.PSUseCorrectCasing.CheckCommands -eq $true -and
            $Settings.Rules.PSUseCorrectCasing.CheckKeyword -eq $true -and
            $Settings.Rules.PSUseCorrectCasing.CheckOperator -eq $true -and
            $Fix -eq $true -and
            $Recurse -eq $false -and
            $ReportSummary -eq $false -and
            $EnableExit -eq $false -and
            $ErrorAction -eq 'Stop'
        }
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.Rules.PSUseCorrectCasing.Enable -eq $false -and
            $Recurse -eq $true -and
            $ReportSummary -eq $true -and
            $ErrorAction -eq 'Stop'
        }
        $scriptAnalyzerArguments.Settings | Should -BeExactly $script:defaultSettingsPath
    }

    It 'should invoke PSScriptAnalyzer unchanged when command casing does not need the workaround' {
        $settingsPath = Join-Path -Path $TestDrive -ChildPath 'DisabledCasingSettings.psd1'
        @'
@{
    Rules = @{
        PSUseCorrectCasing = @{
            Enable = $false
        }
    }
}
'@ | Set-Content -Path $settingsPath
        $scriptAnalyzerArguments = @{
            Path          = $TestDrive
            Settings      = $settingsPath
            Recurse       = $true
            Severity      = 'Information'
            EnableExit    = $false
            ReportSummary = $true
            ErrorAction   = 'Stop'
            Fix           = $true
        }
        Mock Invoke-ScriptAnalyzer {}

        Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArguments

        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings -eq $settingsPath -and
            $Recurse -eq $true -and
            $ReportSummary -eq $true -and
            $Fix -eq $true -and
            $ErrorAction -eq 'Stop'
        }
    }
}

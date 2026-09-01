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

    It 'should accept settings as a hashtable and leave the caller''s copy untouched' {
        $fixtureDir = Join-Path -Path $TestDrive -ChildPath 'HashtableSettingsFixture'
        $null = New-Item -ItemType Directory -Path $fixtureDir -Force
        "function Get-Only { 'only' }" | Set-Content -Path "$fixtureDir/Only.ps1"
        $callerSettings = Import-PowerShellDataFile -Path $script:defaultSettingsPath
        $scriptAnalyzerArguments = @{
            Path          = $fixtureDir
            Settings      = $callerSettings
            Recurse       = $true
            Severity      = 'Information'
            EnableExit    = $false
            ReportSummary = $true
            ErrorAction   = 'Stop'
        }
        Mock Invoke-ScriptAnalyzer {}

        Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArguments

        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.IncludeRules -contains 'PSUseCorrectCasing' -and
            $Path -like '*Only.ps1'
        }
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.Rules.PSUseCorrectCasing.Enable -eq $false -and
            $Recurse -eq $true
        }
        $callerSettings.Rules.PSUseCorrectCasing.Enable | Should -BeTrue
    }

    It 'should enumerate only the top level for the casing pass when Recurse is false' {
        $fixtureDir = Join-Path -Path $TestDrive -ChildPath 'NonRecursiveCasingFixture'
        $nestedDir = Join-Path -Path $fixtureDir -ChildPath 'Nested'
        $null = New-Item -ItemType Directory -Path $nestedDir -Force
        "function Get-First { 'first' }" | Set-Content -Path "$fixtureDir/First.ps1"
        "function Get-Second { 'second' }" | Set-Content -Path "$nestedDir/Second.ps1"
        $scriptAnalyzerArguments = @{
            Path          = $fixtureDir
            Settings      = $script:defaultSettingsPath
            Recurse       = $false
            Severity      = 'Information'
            EnableExit    = $false
            ReportSummary = $true
            ErrorAction   = 'Stop'
        }
        Mock Invoke-ScriptAnalyzer {}

        Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArguments

        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.IncludeRules -contains 'PSUseCorrectCasing' -and
            $Path -like '*First.ps1'
        }
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 0 -ParameterFilter {
            $Path -like '*Second.ps1'
        }
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.Rules.PSUseCorrectCasing.Enable -eq $false -and
            $Recurse -eq $false
        }
    }

    It 'should warn and continue when casing analysis fails for one file' {
        $fixtureDir = Join-Path -Path $TestDrive -ChildPath 'CasingCrashFixture'
        $null = New-Item -ItemType Directory -Path $fixtureDir -Force
        "function Get-Crashing { 'crashing' }" | Set-Content -Path "$fixtureDir/Crashing.ps1"
        "function Get-Healthy { 'healthy' }" | Set-Content -Path "$fixtureDir/Healthy.ps1"
        $scriptAnalyzerArguments = @{
            Path          = $fixtureDir
            Settings      = $script:defaultSettingsPath
            Recurse       = $true
            Severity      = 'Information'
            EnableExit    = $false
            ReportSummary = $true
            ErrorAction   = 'Stop'
        }
        Mock Invoke-ScriptAnalyzer {}
        Mock Invoke-ScriptAnalyzer {
            throw 'Unable to cast object of type FunctionMemberAst to type FunctionDefinitionAst.'
        } -ParameterFilter {
            $Settings.IncludeRules -contains 'PSUseCorrectCasing' -and $Path -like '*Crashing.ps1'
        }

        $warnings = $null
        Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArguments -WarningVariable warnings 3>$null

        $warnings | Should -HaveCount 1
        $warnings[0].Message | Should -BeLike '*Crashing.ps1*'
        $warnings[0].Message | Should -BeLike '*FunctionMemberAst*'
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.IncludeRules -contains 'PSUseCorrectCasing' -and $Path -like '*Healthy.ps1'
        }
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Settings.Rules.PSUseCorrectCasing.Enable -eq $false -and
            $Recurse -eq $true
        }
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

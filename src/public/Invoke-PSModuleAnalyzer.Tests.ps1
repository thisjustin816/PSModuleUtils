# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/Invoke-PSModuleAnalyzer.ps1
        $cleanFile = Join-Path -Path $TestDrive -ChildPath 'Clean.ps1'
        "function Get-Clean { 'ok' }" | Set-Content -Path $cleanFile -Encoding utf8

        <#
        .SYNOPSIS
        Writes test fixture content with consistent line endings.

        .DESCRIPTION
        Normalizes here-string content before writing it to TestDrive so
        Invoke-ScriptAnalyzer -Fix tests do not fail on mixed line endings.
        #>
        function Export-NormalizedTestContent {
            param (
                [Parameter(Mandatory)]
                [string]$Path,

                [Parameter(Mandatory)]
                [string]$Content
            )

            $normalizedContent = (
                ($Content -replace "`r`n|`r|`n", [Environment]::NewLine) +
                [Environment]::NewLine
            )
            Set-Content -Path $Path -Value $normalizedContent -Encoding utf8NoBOM -NoNewline
        }
    }

    It 'should not throw on a clean source directory in fix mode' {
        { Invoke-PSModuleAnalyzer -SourceDirectory $TestDrive -Fix } | Should -Not -Throw
    }

    It 'should only pass Fix to PSScriptAnalyzer in fix mode' {
        Mock Invoke-ScriptAnalyzer {}

        Invoke-PSModuleAnalyzer -SourceDirectory $TestDrive
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            -not $PSBoundParameters.ContainsKey('Fix') -and $EnableExit -eq $true
        }

        Invoke-PSModuleAnalyzer -SourceDirectory $TestDrive -Fix
        Should -Invoke Invoke-ScriptAnalyzer -Exactly -Times 1 -ParameterFilter {
            $Fix -eq $true -and $EnableExit -eq $false
        }
    }

    It 'should preserve nested parentheses containing function definitions in fix mode' {
        $fixtureDir = Join-Path -Path $TestDrive -ChildPath 'IndentationFixture'
        New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null

        $fixturePath = Join-Path -Path $fixtureDir -ChildPath 'NestedParentheses.ps1'
        $fixtureContent = @'
[CmdletBinding()]
param ()

$NestedFunctionRecords = @(
    @{
        Name    = 'array-subexpression'
        Factory = @(
            $prefix = 'alpha'

            function Get-ArraySubexpressionValue {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory)]
                    [string]$Name
                )

                $localValue = (
                    $prefix,
                    $Name,
                    'omega'
                ) -join '-'

                [PSCustomObject]@{
                    Name  = $Name
                    Value = $localValue
                }
            }

            $suffix = 'complete'
        )
    }
    @{
        Name    = 'nested-hashtable'
        Factory = @(
            @{
                Before = @(
                    $leftValue = 'left'
                    $rightValue = 'right'

                    function New-NestedHashtableValue {
                        [CmdletBinding()]
                        param (
                            [Parameter(Mandatory)]
                            [string]$InputValue
                        )

                        $joinedValue = (
                            $leftValue,
                            $InputValue,
                            $rightValue
                        ) -join ':'

                        @{
                            Input  = $InputValue
                            Joined = $joinedValue
                        }
                    }

                    $rightValue
                )
                After  = 'done'
            }
        )
    }
)

$ScriptBlockCases = @(
    {
        $outerValue = 'outer'

        Invoke-Command -ScriptBlock (
            {
                $innerValue = 'inner'

                function Invoke-IndentedScriptBlock {
                    [CmdletBinding()]
                    param (
                        [Parameter(Mandatory)]
                        [string]$Name
                    )

                    $result = (
                        $outerValue,
                        $innerValue,
                        $Name
                    ) -join '/'

                    $result
                }

                Invoke-IndentedScriptBlock -Name 'scriptblock'
            }
        )
    }
    {
        $items = @(
            'one'
            @(
                function Get-ParenthesizedFunctionValue {
                    [CmdletBinding()]
                    param ()

                    $assignedInsideFunction = (
                        'two',
                        'three'
                    ) -join ','

                    $assignedInsideFunction
                }

                Get-ParenthesizedFunctionValue
            )
            'four'
        )

        $items
    }
)

$NestedFunctionRecords
$ScriptBlockCases
'@
        Export-NormalizedTestContent -Path $fixturePath -Content $fixtureContent

        $settingsPath = Join-Path -Path $TestDrive -ChildPath 'IndentationSettings.psd1'
        $settingsContent = @'
@{
    IncludeRules = @(
        'PSUseConsistentIndentation'
    )
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
    }
}
'@
        Export-NormalizedTestContent -Path $settingsPath -Content $settingsContent

        $before = Get-Content -Path $fixturePath -Raw
        Invoke-PSModuleAnalyzer -SourceDirectory $fixtureDir -Settings $settingsPath -Fix
        $after = Get-Content -Path $fixturePath -Raw

        $after | Should -BeExactly $before
    }

    It 'should accept a custom settings file path' {
        $customSettingsDir = Join-Path -Path $TestDrive -ChildPath 'CustomSettingsFixture'
        New-Item -ItemType Directory -Path $customSettingsDir -Force | Out-Null
        $customSettingsFile = Join-Path -Path $customSettingsDir -ChildPath 'Clean.ps1'
        "function Get-Clean { 'ok' }" | Set-Content -Path $customSettingsFile -Encoding utf8

        $settings = Resolve-Path -Path "$PSScriptRoot/../private/PSScriptAnalyzerSettings.psd1"
        { Invoke-PSModuleAnalyzer -SourceDirectory $customSettingsDir -Settings $settings -Fix } |
            Should -Not -Throw
    }
}

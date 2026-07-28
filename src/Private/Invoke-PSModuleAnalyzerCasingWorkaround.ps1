<#
.SYNOPSIS
Internal: invokes PSScriptAnalyzer with a temporary command-casing workaround.

.DESCRIPTION
Runs PSUseCorrectCasing sequentially per file when command casing is enabled, then runs the remaining analysis
recursively. PSScriptAnalyzer 1.25.0 can fail while resolving command metadata during a recursive multi-file
command-casing analysis.

.PARAMETER Path
The file or directory to analyze.

.PARAMETER Settings
The PSScriptAnalyzer settings file to use.

.PARAMETER Recurse
Analyzes files recursively.

.PARAMETER Severity
The diagnostic severities to return.

.PARAMETER EnableExit
Exits with the number of diagnostics found.

.PARAMETER ReportSummary
Writes a diagnostic summary.

.PARAMETER Fix
Applies supported corrections.

.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord
#>
function Invoke-PSModuleAnalyzerCasingWorkaround {
    [CmdletBinding()]
    [OutputType('Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord')]
    param (
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter(Mandatory)]
        [String]$Settings,

        [Switch]$Recurse,

        [String[]]$Severity,

        [Switch]$EnableExit,

        [Switch]$ReportSummary,

        [Switch]$Fix
    )

    $recursiveAnalyzerArguments = @{}
    foreach ($argument in $PSBoundParameters.GetEnumerator()) {
        $recursiveAnalyzerArguments[$argument.Key] = $argument.Value
    }

    $settingsData = Import-PowerShellDataFile -Path $Settings -ErrorAction Stop
    $correctCasingRule = $settingsData.Rules.PSUseCorrectCasing
    $includeRules = @($settingsData.IncludeRules | Where-Object { $_ })
    $excludeRules = @($settingsData.ExcludeRules | Where-Object { $_ })
    $correctCasingIncluded = (
        $includeRules.Count -eq 0 -or
        @($includeRules | Where-Object { 'PSUseCorrectCasing' -like $_ }).Count -gt 0
    )
    $correctCasingExcluded = @(
        $excludeRules | Where-Object { 'PSUseCorrectCasing' -like $_ }
    ).Count -gt 0
    $splitCommandCasing = (
        $correctCasingRule.Enable -eq $true -and
        $correctCasingRule.CheckCommands -ne $false -and
        $correctCasingIncluded -and
        -not $correctCasingExcluded
    )

    if ($splitCommandCasing) {
        $settingsData.Rules.PSUseCorrectCasing.Enable = $false
        $recursiveAnalyzerArguments.Settings = $settingsData
        $casingSettings = @{
            IncludeRules = @('PSUseCorrectCasing')
            Rules        = @{
                PSUseCorrectCasing = @{
                    Enable        = $true
                    CheckCommands = $true
                    CheckKeyword  = ($correctCasingRule.CheckKeyword -ne $false)
                    CheckOperator = ($correctCasingRule.CheckOperator -ne $false)
                }
            }
        }
        $casingArguments = @{
            Settings      = $casingSettings
            Recurse       = $false
            Severity      = $Severity
            EnableExit    = $false
            ReportSummary = $false
            ErrorAction   = 'Stop'
        }
        if ($Fix) {
            $casingArguments.Fix = $true
        }

        $casingResultCount = 0
        Get-ChildItem -Path $Path -Recurse:$Recurse -File -ErrorAction Stop |
            Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1' } |
            ForEach-Object {
                $casingArguments.Path = $_.FullName
                Invoke-ScriptAnalyzer @casingArguments |
                    ForEach-Object {
                        $casingResultCount++
                        $_
                    }
                }

        Invoke-ScriptAnalyzer @recursiveAnalyzerArguments

        if ($EnableExit -and -not $Fix -and $casingResultCount -gt 0) {
            exit [Math]::Min($casingResultCount, 255)
        }
    }
    else {
        Invoke-ScriptAnalyzer @recursiveAnalyzerArguments
    }
}

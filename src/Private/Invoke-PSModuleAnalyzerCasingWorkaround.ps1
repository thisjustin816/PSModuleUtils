<#
.SYNOPSIS
Internal: invokes PSScriptAnalyzer with a temporary command-casing workaround.

.DESCRIPTION
Runs PSUseCorrectCasing sequentially per file when command casing is enabled, then runs the remaining analysis
recursively. PSScriptAnalyzer 1.25.0 can fail while resolving command metadata during command-casing analysis;
splitting the run keeps one file's failure from silencing every other rule. A file whose casing analysis still
fails on its own is reported as a warning and skipped for that rule alone - the recursive pass analyzes it with
everything else.

.PARAMETER Path
The file or directory to analyze.

.PARAMETER Settings
A settings file path or a settings hashtable, as Invoke-ScriptAnalyzer itself accepts. A hashtable is
not modified; the split run gets a copy with command casing disabled.

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
        [Object]$Settings,

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

    $settingsData = if ($Settings -is [Collections.IDictionary]) {
        $Settings
    }
    else {
        Import-PowerShellDataFile -Path $Settings -ErrorAction Stop
    }
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
        # Copied rather than edited in place, because a caller that passed a hashtable still owns it.
        $recursiveCasingRule = @{} + $correctCasingRule
        $recursiveCasingRule.Enable = $false
        $recursiveRules = @{} + $settingsData.Rules
        $recursiveRules.PSUseCorrectCasing = $recursiveCasingRule
        $recursiveSettings = @{} + $settingsData
        $recursiveSettings.Rules = $recursiveRules
        $recursiveAnalyzerArguments.Settings = $recursiveSettings
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
                # The metadata-resolution failure this function exists for can
                # also strike a single-file analysis, so one broken file must
                # not end the run: the recursive pass below still analyzes it
                # with every rule except casing, and the warning keeps the
                # skip from being silent.
                try {
                    Invoke-ScriptAnalyzer @casingArguments |
                        ForEach-Object {
                            $casingResultCount++
                            $_
                        }
                    }
                    catch {
                        $casingFailure = $_
                        Write-Warning (
                            "PSUseCorrectCasing analysis failed for '$($casingArguments.Path)' and was " +
                            'skipped for that file; the remaining rules still analyze it. ' +
                            "Underlying error: $($casingFailure.Exception.Message)"
                        )
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

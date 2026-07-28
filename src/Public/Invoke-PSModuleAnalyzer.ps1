<#
.SYNOPSIS
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.DESCRIPTION
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.PARAMETER SourceDirectory
The directory to analyze. Also accepts a file path or a wildcard such as scripts/*.ps1, which pairs
with -NoRecurse to analyze a directory's own scripts without descending into folders beneath it.

.PARAMETER Settings
The settings file to use. Defaults to the bundled PSScriptAnalyzerSettings.psd1, resolved for both a
source checkout and a built module layout.

.PARAMETER Fix
Whether to fix the issues found.

.PARAMETER NoExit
Returns analyzer diagnostics without exiting the caller when violations are found. Use this when another
command needs to process the diagnostics, such as converting them to SARIF.

.PARAMETER NoRecurse
Analyzes only what SourceDirectory itself matches instead of descending into subdirectories. Use with
a wildcard to keep a subtree with different rules, such as a tests folder, out of the run.

.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/src -Fix

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/scripts/*.ps1 -NoRecurse

.NOTES
N/A
#>
function Invoke-PSModuleAnalyzer {
    [CmdletBinding()]
    [OutputType('Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord')]
    param (
        [String]$SourceDirectory = "$PWD/src",
        [String]$Settings = (Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot $PSScriptRoot),
        [Switch]$Fix,
        [Switch]$NoExit,
        [Switch]$NoRecurse
    )

    $scriptAnalyzerArgs = @{
        Path          = $SourceDirectory
        Settings      = $Settings
        Recurse       = (-not $NoRecurse)
        Severity      = 'Error', 'Warning', 'Information'
        EnableExit    = (-not $Fix -and -not $NoExit)
        ReportSummary = $true
        ErrorAction   = 'Stop'
    }

    if ($Fix) {
        $scriptAnalyzerArgs.Fix = $true
    }

    # After PSScriptAnalyzer fixes recursive PSUseCorrectCasing command metadata resolution, uncomment this call
    # and remove the private workaround and its tests.
    # Invoke-ScriptAnalyzer @scriptAnalyzerArgs
    Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArgs
}

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

.PARAMETER ErrorOnFinding
Throws when the analyzer reports anything, rather than setting the process exit code. Required to
gate a script that analyzes more than one path: PSScriptAnalyzer's exit code is last-writer-wins and
does not stop the caller, so a clean pass after a failing one leaves the run reporting success.

.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/src -Fix

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/scripts/*.ps1 -NoRecurse

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/tests -ErrorOnFinding

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
        [Switch]$NoRecurse,
        [Switch]$ErrorOnFinding
    )

    $scriptAnalyzerArgs = @{
        Path          = $SourceDirectory
        Settings      = $Settings
        Recurse       = (-not $NoRecurse)
        Severity      = 'Error', 'Warning', 'Information'
        EnableExit    = (-not $Fix -and -not $NoExit -and -not $ErrorOnFinding)
        ReportSummary = $true
        ErrorAction   = 'Stop'
    }

    if ($Fix) {
        $scriptAnalyzerArgs.Fix = $true
    }

    # After PSScriptAnalyzer fixes recursive PSUseCorrectCasing command metadata resolution, uncomment
    # these calls and remove the private workaround and its tests.
    if ($ErrorOnFinding) {
        # $diagnostics = @(Invoke-ScriptAnalyzer @scriptAnalyzerArgs)
        $diagnostics = @(Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArgs)

        if ($diagnostics) {
            # Written to the host as well as thrown: the throw discards the records, and a count on its
            # own does not say what to fix.
            Write-Host -Object ($diagnostics | Format-Table -AutoSize | Out-String -Width 200)
            throw "$($diagnostics.Count) rule violation(s) found in '$SourceDirectory'."
        }
    }
    else {
        # Invoke-ScriptAnalyzer @scriptAnalyzerArgs
        Invoke-PSModuleAnalyzerCasingWorkaround @scriptAnalyzerArgs
    }
}

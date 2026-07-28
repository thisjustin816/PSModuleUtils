<#
.SYNOPSIS
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.DESCRIPTION
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default, and works
around its recursive PSUseCorrectCasing crash by applying that one rule a file at a time.

Returns diagnostics, like Invoke-ScriptAnalyzer does. Decide what a finding means at the call site:
throw to gate a build, pipe to ConvertTo-SARIF to report one, or pass -EnableExit for a CI step that
should fail on its exit code.

.PARAMETER SourceDirectory
The directory to analyze. Also accepts a file path or a wildcard such as scripts/*.ps1, which pairs
with -NoRecurse to analyze a directory's own scripts without descending into folders beneath it.

.PARAMETER Settings
The settings file to use. Defaults to the bundled PSScriptAnalyzerSettings.psd1, resolved for both a
source checkout and a built module layout.

.PARAMETER Fix
Whether to fix the issues found.

.PARAMETER NoRecurse
Analyzes only what SourceDirectory itself matches instead of descending into subdirectories. Use with
a wildcard to keep a subtree with different rules, such as a tests folder, out of the run.

.PARAMETER EnableExit
Passed through to Invoke-ScriptAnalyzer: asks the host to exit with the diagnostic count once the run
finishes. Suits a CI step that is one analyzer call. It does not stop the caller and the code is
last-writer-wins, so a script analyzing several paths should test the returned diagnostics instead.

.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/src -Fix

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/scripts/*.ps1 -NoRecurse

.EXAMPLE
$findings = Invoke-PSModuleAnalyzer -SourceDirectory $PWD/tests
if ($findings) {
    throw "$($findings.Count) rule violation(s) in tests."
}

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/src -EnableExit

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
        [Switch]$NoRecurse,
        [Switch]$EnableExit
    )

    $scriptAnalyzerArgs = @{
        Path          = $SourceDirectory
        Settings      = $Settings
        Recurse       = (-not $NoRecurse)
        Severity      = 'Error', 'Warning', 'Information'
        EnableExit    = $EnableExit
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

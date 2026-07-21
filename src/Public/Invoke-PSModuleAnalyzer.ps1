<#
.SYNOPSIS
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.DESCRIPTION
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.PARAMETER SourceDirectory
The directory to analyze.

.PARAMETER Settings
The settings file to use. Defaults to the bundled PSScriptAnalyzerSettings.psd1, resolved for both a
source checkout and a built module layout.

.PARAMETER Fix
Whether to fix the issues found.

.OUTPUTS
Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/src -Fix

.NOTES
N/A
#>
function Invoke-PSModuleAnalyzer {
    [CmdletBinding()]
    [OutputType('Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord')]
    param (
        [String]$SourceDirectory = "$PWD/src",
        [String]$Settings = (Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot $PSScriptRoot),
        [Switch]$Fix
    )

    $scriptAnalyzerArgs = @{
        Path          = $SourceDirectory
        Settings      = $Settings
        Recurse       = $true
        Severity      = 'Information'
        EnableExit    = (-not $Fix)
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

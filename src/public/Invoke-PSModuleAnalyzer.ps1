<#
.SYNOPSIS
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.DESCRIPTION
Invokes PSScriptAnalyzer on a directory using a more strict set of rules than default.

.PARAMETER SourceDirectory
The directory to analyze.

.PARAMETER Settings
The settings file to use. Defaults to internal custom file.

.PARAMETER Fix
Whether to fix the issues found.

.EXAMPLE
Invoke-PSModuleAnalyzer -SourceDirectory $PWD/src -Fix

.NOTES
N/A
#>
function Invoke-PSModuleAnalyzer {
    [CmdletBinding()]
    param (
        [String]$SourceDirectory = "$PWD/src",
        [String]$Settings = "$PSScriptRoot/../private/PSScriptAnalyzerSettings.psd1",
        [Switch]$Fix
    )

    Invoke-ScriptAnalyzer `
        -Path $SourceDirectory `
        -Settings $Settings `
        -Recurse `
        -Severity Information `
        -Fix:$Fix `
        -EnableExit:(!$Fix) `
        -ReportSummary
}

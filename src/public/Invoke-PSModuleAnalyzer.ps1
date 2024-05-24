function Invoke-PSModuleAnalyzer {
    [CmdletBinding()]
    param (
        [String]$SourceDirectory = "$PWD/src",
        [Switch]$Fix
    )

    Invoke-ScriptAnalyzer `
        -Path $SourceDirectory `
        -Recurse `
        -Severity Information `
        -Fix:$Fix `
        -EnableExit:(!$Fix) `
        -ReportSummary
}

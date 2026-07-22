<#
.SYNOPSIS
Internal: resolves the bundled analyzer settings across source and built module layouts.

.DESCRIPTION
ModuleBuilder merges every source function into a single flat .psm1 while copying the Settings directory
intact. The settings directory is one level above a source function and a direct sibling of the built
.psm1. This probes both locations relative to the caller's own $PSScriptRoot.

.PARAMETER CallerScriptRoot
The $PSScriptRoot of the calling function.

.OUTPUTS
System.String path to the settings file, or nothing if neither candidate exists.

.EXAMPLE
Get-PSModuleAnalyzerSettingsPath -CallerScriptRoot $PSScriptRoot
#>
function Get-PSModuleAnalyzerSettingsPath {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory)]
        [String]$CallerScriptRoot
    )

    $candidates = @(
        (Join-Path -Path $CallerScriptRoot -ChildPath 'Settings/PSScriptAnalyzerSettings.psd1')
        (Join-Path -Path $CallerScriptRoot -ChildPath '../Settings/PSScriptAnalyzerSettings.psd1')
    )
    $candidates | Where-Object -FilterScript { Test-Path -Path $_ } | Select-Object -First 1
}

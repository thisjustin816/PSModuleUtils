<#
.SYNOPSIS
Internal: returns analyzer settings with the compatibility rules retargeted.

.DESCRIPTION
PSScriptAnalyzer has no single setting for "which PowerShell version am I targeting". Five rules
each carry their own target, in three different identifier formats: PSUseCompatibleSyntax takes
version strings, PSUseCompatibleCommands and PSUseCompatibleTypes take platform profile names, and
PSUseCompatibleCmdlets and PSAvoidOverwritingBuiltInCmdlets take a third edition-and-version form.
This maps one friendly version onto all five.

Returns a new settings table. The caller's own table and its rule entries are left untouched, so a
settings hashtable can be reused across calls with different targets.

.PARAMETER Settings
A settings file path or a settings hashtable.

.PARAMETER TargetVersion
The PowerShell versions to target.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
Get-PSModuleAnalyzerTargetSettings -Settings ./PSScriptAnalyzerSettings.psd1 -TargetVersion 7.0
#>
function Get-PSModuleAnalyzerTargetSettings {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory)]
        [Object]$Settings,

        [Parameter(Mandatory)]
        [ValidateSet('5.1', '7.0')]
        [String[]]$TargetVersion
    )

    # PSUseCompatibleCmdlets ships no 7.x catalogue; core-6.1.0 is the newest core baseline it
    # knows, so 7.0 maps onto it rather than dropping the rule.
    $versionMap = @{
        '5.1' = @{
            Syntax  = '5.1'
            Profile = 'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            Cmdlet  = 'desktop-5.1.14393.206-windows'
        }
        '7.0' = @{
            Syntax  = '7.0'
            Profile = 'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
            Cmdlet  = 'core-6.1.0-windows'
        }
    }

    $source = if ($Settings -is [Hashtable]) {
        $Settings
    }
    else {
        Import-PowerShellDataFile -Path $Settings -ErrorAction Stop
    }

    $resolved = @{}
    foreach ($key in $source.Keys) {
        $resolved[$key] = $source[$key]
    }

    $rules = @{}
    if ($source.ContainsKey('Rules') -and $source.Rules -is [Hashtable]) {
        foreach ($rule in $source.Rules.Keys) {
            $rules[$rule] = $source.Rules[$rule]
        }
    }
    $resolved.Rules = $rules

    $selected = $versionMap[$TargetVersion]
    $syntaxVersions = @($selected.Syntax)
    $profiles = @($selected.Profile)
    $cmdletVersions = @($selected.Cmdlet)

    # Replace whole rule entries rather than editing them, so a rule table shared with the
    # caller's settings is never modified. Keys the target does not own, such as IgnoreCommands,
    # are carried across.
    $retarget = {
        param([String]$RuleName, [String]$Key, [Object]$Value)

        $entry = @{}
        if ($rules.ContainsKey($RuleName) -and $rules[$RuleName] -is [Hashtable]) {
            foreach ($existing in $rules[$RuleName].Keys) {
                $entry[$existing] = $rules[$RuleName][$existing]
            }
        }

        $entry[$Key] = $Value
        $rules[$RuleName] = $entry
    }

    & $retarget 'PSUseCompatibleSyntax' 'TargetVersions' $syntaxVersions
    & $retarget 'PSUseCompatibleCommands' 'TargetProfiles' $profiles
    & $retarget 'PSUseCompatibleTypes' 'TargetProfiles' $profiles
    & $retarget 'PSUseCompatibleCmdlets' 'compatibility' $cmdletVersions
    & $retarget 'PSAvoidOverwritingBuiltInCmdlets' 'PowerShellVersion' $cmdletVersions

    $resolved
}

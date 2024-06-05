#Requires -Modules @{ ModuleName = 'Pester'; MaximumVersion = '6.0.0' }, @{ ModuleName = 'PSScriptAnalyzer'; MaximumVersion = '2.0.0' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidLongLines', '')]
[CmdletBinding()]
param ()

Get-ChildItem -Path "$PSScriptRoot/public" -Filter '*.ps1' -Exclude '*.Tests.ps1' -File -Recurse |
    ForEach-Object -Process {
        . $_.FullName
    }

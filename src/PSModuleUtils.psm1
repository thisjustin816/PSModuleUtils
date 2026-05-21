#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0'; MaximumVersion = '5.99.99' }, @{ ModuleName = 'PSScriptAnalyzer'; MaximumVersion = '1.99.99' }
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidLongLines', '')]
[CmdletBinding()]
param ()

Get-ChildItem -Path "$PSScriptRoot/public" -Filter '*.ps1' -Exclude '*.Tests.ps1' -File -Recurse |
    ForEach-Object -Process {
        . $_.FullName
    }

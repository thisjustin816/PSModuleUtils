#Requires -Version 7.4
[CmdletBinding()]
param ()

$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $PSScriptRoot
try {
    $manifest = Import-PowerShellDataFile -LiteralPath "$PSScriptRoot/src/PSModuleUtils.psd1"
    foreach ($requiredModule in $manifest.RequiredModules) {
        Import-Module -FullyQualifiedName $requiredModule -ErrorAction Stop
    }
    Get-ChildItem -Path "$PSScriptRoot/src/Private", "$PSScriptRoot/src/Public" -Filter '*.ps1' -Recurse |
        ForEach-Object { . $_.FullName }

    if (-not $env:GITHUB_ACTIONS) {
        Invoke-PSModuleAnalyzer -Fix
    }
    $builtManifest = Build-PSModule
    Test-PSModule -Name $builtManifest.BaseName
    $builtManifest
}
finally {
    Pop-Location
}

Push-Location -Path $PSScriptRoot
Import-Module -Name 'PSModuleUtils' -MinimumVersion '2.0.0' -Force -ErrorAction Stop
Get-ChildItem -Path "$PSScriptRoot/src/Private", "$PSScriptRoot/src/Public" -Filter '*.ps1' -Recurse |
    ForEach-Object -Process { . $_.FullName }
if (-not $env:GITHUB_ACTIONS) {
    Invoke-PSModuleAnalyzer -Fix
}
$builtManifest = Build-PSModule
Test-PSModule -Name $builtManifest.BaseName
Pop-Location
$builtManifest

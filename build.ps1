$BuildPSModule = @{
    Name      = 'PSModuleUtils'
    Version   = '2.0.1'
    CopyPaths = 'Settings'
}

Push-Location -Path $PSScriptRoot
Import-Module -Name 'PSModuleUtils' -MinimumVersion '2.0.0' -Force -ErrorAction Stop
Get-ChildItem -Path "$PSScriptRoot/src/Private", "$PSScriptRoot/src/Public" -Filter '*.ps1' -Recurse |
    ForEach-Object -Process { . $_.FullName }
if (-not $env:GITHUB_ACTIONS) {
    Invoke-PSModuleAnalyzer -Fix
}
Build-PSModule @BuildPSModule
Test-PSModule -Name $BuildPSModule['Name']
Pop-Location

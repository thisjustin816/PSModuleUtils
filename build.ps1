$BuildPSModule = @{
    Name      = 'PSModuleUtils'
    Version   = '2.0.0'
    CopyPaths = 'Settings'
}

Push-Location -Path $PSScriptRoot
Import-Module -FullyQualifiedName @{
    ModuleName     = 'ModuleBuilder'
    ModuleVersion  = '3.0.0'
    MaximumVersion = '3.*'
},
@{
    ModuleName     = 'Metadata'
    ModuleVersion  = '1.5.0'
    MaximumVersion = '1.*'
} -ErrorAction Stop
Import-Module -Name 'Pester' -MinimumVersion '5.0' -MaximumVersion '5.*' -ErrorAction Stop
Get-ChildItem -Path "$PSScriptRoot/src/Private", "$PSScriptRoot/src/Public" -Filter '*.ps1' -Recurse |
    ForEach-Object -Process { . $_.FullName }
if (-not $env:GITHUB_ACTIONS) {
    Invoke-PSModuleAnalyzer -Fix
}
Build-PSModule @BuildPSModule
Test-PSModule -Name $BuildPSModule['Name']
Pop-Location

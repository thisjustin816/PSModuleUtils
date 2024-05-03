function Test-PSModule {
    [CmdletBinding()]
    param (
        [String]$Name = 'PSModule',
        [String]$SourceDirectory = "$PWD/src",
        [String[]]$Tag
    )

    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    $config = [PesterConfiguration]::Default
    if ($Tag) {
        $config.Filter.Tag = 'Unit'
    }
    $config.Run.Path = $SourceDirectory
    $config.Run.Exit = $true
    $config.Run.Throw = $true
    $config.Output.Verbosity = 'Detailed'

    Invoke-Pester -Configuration $config
}
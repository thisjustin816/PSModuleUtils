function Test-PSModule {
    [CmdletBinding()]
    param (
        [String]$Name = 'PSModule',
        [String]$SourceDirectory = "$PWD/src",
        [String[]]$Tag
    )

    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    $config = New-PesterConfiguration @{
        Run          = @{
            Path  = $SourceDirectory
        }
        CodeCoverage = @{
            Enabled    = $true
            OutputPath = 'tests/coverage.xml'
        }
        TestResult   = @{
            Enabled    = $true
            OutputPath = 'tests/testResults.xml'
        }
        Output       = @{
            Verbosity = 'Detailed'
        }
    }
    if ($Tag) {
        $config.Filter.Tag = 'Unit'
    }

    # TODO: Remove after implementing test result publishing 
    $config.Run.Exit = $true
    $config.Run.Throw = $true

    Invoke-Pester -Configuration $config
}
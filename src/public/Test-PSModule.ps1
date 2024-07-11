<#
.SYNOPSIS
Tests a PowerShell module using Pester.

.DESCRIPTION
Tests a PowerShell module using Pester. The function installs Pester, removes any existing module with the same name,
and runs Pester with a configuration optimized for running in a CI pipeline.

.PARAMETER Name
The name of the module.

.PARAMETER SourceDirectory
The source directory of the module. Should be a nested directory that doesn't contain and build scripts.

.PARAMETER Exclude
The directories to exclude from testing and code coverage.

.PARAMETER Tag
The tag to filter tests by.

.EXAMPLE
Test-PSModule -Name 'MyModule' -SourceDirectory "$PWD/src" -Tag 'Unit'

.NOTES
N/A
#>
function Test-PSModule {
    [CmdletBinding()]
    param (
        [String]$Name = 'PSModule',
        [String]$SourceDirectory = "$PWD/src",
        [String[]]$Exclude,
        [String[]]$Tag
    )

    $testFiles = Get-ChildItem -Path $SourceDirectory -Filter '*.Tests.ps1' -Recurse
    if (-not $testFiles) {
        Write-Warning -Message "No test files found in $SourceDirectory"
        return
    }
    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    $config = New-PesterConfiguration @{
        Run          = @{
            Path        = $SourceDirectory
            ExcludePath = $Exclude
        }
        CodeCoverage = @{
            Enabled    = $true
            OutputPath = 'tests/coverage.xml'
        }
        TestResult   = @{
            Enabled    = $true
            OutputPath = 'tests/testResults.xml'
        }
        Output       = @{
            Verbosity = 'Detailed'
        }
    }
    if ($Tag) {
        $config.Filter.Tag = 'Unit'
    }

    # TODO: Remove after implementing test result publishing
    $config.Run.Exit = $true
    $config.Run.Throw = $true

    Write-Verbose -Message 'Running Pester tests with the following configuration:'
    Write-Verbose -Message ( $config | ConvertTo-Json -Depth 5 )
    Invoke-Pester -Configuration $config
}
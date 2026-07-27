<#
.SYNOPSIS
Tests a PowerShell module using Pester.

.DESCRIPTION
Tests a PowerShell module using Pester. The function installs Pester, removes any existing module with the same name,
and runs Pester with a configuration optimized for running in a CI pipeline.

.PARAMETER Name
The name of the module.

.PARAMETER SourceDirectory
The source directory of the module. Used as the code coverage target, not for test discovery.

.PARAMETER TestPath
The directory to discover and run "*.Tests.ps1" files from.

.PARAMETER ResultsDirectory
The directory to write testResults.xml and coverage.xml to. Defaults to "tests" under the current
directory, where they land beside the test sources; pass a build output directory to keep generated
reports with the other build artifacts.

.PARAMETER Exclude
The directories to exclude from testing and code coverage.

.PARAMETER Tag
The tag to filter tests by.

.EXAMPLE
Test-PSModule -Name 'MyModule' -SourceDirectory "$PWD/src" -TestPath "$PWD/tests" -Tag 'Unit'

.NOTES
N/A
#>
function Test-PSModule {
    [CmdletBinding()]
    param (
        [String]$Name = 'PSModule',
        [String]$SourceDirectory = "$PWD/src",
        [String]$TestPath = "$PWD/tests",
        [String]$ResultsDirectory = "$PWD/tests",
        [String[]]$Exclude,
        [String[]]$Tag
    )

    $testFiles = Get-ChildItem -Path $TestPath -Filter '*.Tests.ps1' -Recurse -ErrorAction SilentlyContinue
    if (-not $testFiles) {
        Write-Warning -Message "No test files found in $TestPath"
        return
    }
    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    $config = New-PesterConfiguration @{
        Run          = @{
            Path        = $TestPath
            ExcludePath = $Exclude
        }
        CodeCoverage = @{
            Enabled    = $true
            Path       = $SourceDirectory
            OutputPath = Join-Path $ResultsDirectory 'coverage.xml'
        }
        TestResult   = @{
            Enabled    = $true
            OutputPath = Join-Path $ResultsDirectory 'testResults.xml'
        }
        Output       = @{
            Verbosity = 'Detailed'
        }
    }
    if ($Tag) {
        $config.Filter.Tag = $Tag
    }

    $config.Run.Throw = $true

    Write-Verbose -Message 'Running Pester tests with the following configuration:'
    Write-Verbose -Message ( $config | ConvertTo-Json -Depth 5 )
    Invoke-Pester -Configuration $config
}
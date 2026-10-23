<#
.SYNOPSIS
Tests a PowerShell module using Pester.

.DESCRIPTION
Tests a PowerShell module using the required Pester version. Removes any existing module with the same name,
and writes test and coverage reports for CI. Discovered suites must pass at least one test.
A directory without test files retains the warning-and-return behavior.

.PARAMETER Name
The name of the module.

.PARAMETER SourceDirectory
The source directory of the module. Used as the code coverage target, not for test discovery.

.PARAMETER TestPath
The directory to discover and run "*.Tests.ps1" files from.

.PARAMETER ResultsDirectory
The directory to write testResults.xml and coverage.xml to. Defaults to "out/tests" under the
current directory, keeping generated reports with the other build artifacts instead of beside the
test sources.

.PARAMETER Exclude
The files or directories to exclude from test discovery. Does not change the code coverage target.

.PARAMETER Tag
The tag to filter tests by.

.PARAMETER ExcludeTag
Tags to exclude from execution, such as tests requiring a disposable host or live service.

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
        [String]$ResultsDirectory = "$PWD/out/tests",
        [String[]]$Exclude,
        [String[]]$Tag,
        [String[]]$ExcludeTag
    )

    $testFiles = Get-ChildItem -Path $TestPath -Filter '*.Tests.ps1' -Recurse -ErrorAction SilentlyContinue
    if (-not $testFiles) {
        Write-Warning -Message "No test files found in $TestPath"
        return
    }
    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    $config = New-PesterConfiguration @{
        Run          = @{
            PassThru    = $true
            Path        = $TestPath
            ExcludePath = $Exclude
        }
        CodeCoverage = @{
            Enabled      = $true
            OutputFormat = 'JaCoCo'
            ReportRoot   = $SourceDirectory
            Path         = $SourceDirectory
            OutputPath   = Join-Path $ResultsDirectory 'coverage.xml'
        }
        TestResult   = @{
            Enabled      = $true
            OutputFormat = 'NUnitXml'
            OutputPath   = Join-Path $ResultsDirectory 'testResults.xml'
        }
        Output       = @{
            Verbosity = 'Detailed'
        }
    }
    if ($Tag) {
        $config.Filter.Tag = $Tag
    }

    if ($ExcludeTag) {
        $config.Filter.ExcludeTag = $ExcludeTag
    }

    $config.Run.Throw = $true

    Write-Verbose -Message 'Running Pester tests with the following configuration:'
    Write-Verbose -Message ( $config | ConvertTo-Json -Depth 5 )
    $result = Invoke-Pester -Configuration $config
    if ($result.PassedCount -eq 0) {
        throw 'Pester did not execute any passing tests. Check the selected paths, tags, and skips.'
    }
}
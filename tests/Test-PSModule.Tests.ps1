# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Public/Test-PSModule.ps1
    }

    Context 'when no test files are found' {
        It 'should warn and not invoke Pester' {
            $emptyDir = Join-Path -Path $TestDrive -ChildPath 'no-tests'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            Mock Invoke-Pester {}
            Test-PSModule `
                -Name 'TestModule' `
                -TestPath $emptyDir `
                -WarningVariable warnings `
                -WarningAction SilentlyContinue
            ( $warnings -join ' ' ) | Should -Match 'No test files found'
            Should -Invoke Invoke-Pester -Times 0
        }
    }

    Context 'when test files are present' {
        BeforeEach {
            $script:testDir = Join-Path -Path $TestDrive -ChildPath 'with-tests'
            New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
            $sample = 'Describe "x" { It "y" { $true | Should -BeTrue } }'
            Set-Content -Path (Join-Path -Path $script:testDir -ChildPath 'Sample.Tests.ps1') -Value $sample
            Mock Invoke-Pester {}
        }

        It 'should invoke Pester with the test path in the configuration' {
            Test-PSModule -Name 'TestModule' -TestPath $script:testDir
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.Run.Path.Value -contains $script:testDir
            }
        }

        It 'should throw on failed tests without exiting the caller host' {
            Test-PSModule -Name 'TestModule' -TestPath $script:testDir
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.Run.Throw.Value -and -not $Configuration.Run.Exit.Value
            }
        }
        It 'should set a Tag filter when -Tag is provided' {
            Test-PSModule -Name 'TestModule' -TestPath $script:testDir -Tag 'Unit'
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.Filter.Tag.Value -contains 'Unit'
            }
        }

        It 'should write reports with the build artifacts by default' {
            Test-PSModule -Name 'TestModule' -TestPath $script:testDir
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.TestResult.OutputPath.Value -eq (Join-Path "$PWD/out/tests" 'testResults.xml') -and
                $Configuration.CodeCoverage.OutputPath.Value -eq (Join-Path "$PWD/out/tests" 'coverage.xml')
            }
        }

        It 'should write reports to the requested results directory' {
            $resultsDir = Join-Path -Path $TestDrive -ChildPath 'artifacts'
            Test-PSModule -Name 'TestModule' -TestPath $script:testDir -ResultsDirectory $resultsDir
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.TestResult.OutputPath.Value -eq (Join-Path $resultsDir 'testResults.xml') -and
                $Configuration.CodeCoverage.OutputPath.Value -eq (Join-Path $resultsDir 'coverage.xml')
            }
        }
    }
}

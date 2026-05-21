# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/Test-PSModule.ps1
    }

    Context 'when no test files are found' {
        It 'should warn and not invoke Pester' {
            $emptyDir = Join-Path -Path $TestDrive -ChildPath 'no-tests'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            Mock Invoke-Pester {}
            Test-PSModule `
                -Name 'TestModule' `
                -SourceDirectory $emptyDir `
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

        It 'should invoke Pester with the source directory in the configuration' {
            Test-PSModule -Name 'TestModule' -SourceDirectory $script:testDir
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.Run.Path.Value -contains $script:testDir
            }
        }

        It 'should set a Tag filter when -Tag is provided' {
            Test-PSModule -Name 'TestModule' -SourceDirectory $script:testDir -Tag 'Unit'
            Should -Invoke Invoke-Pester -Times 1 -Exactly -ParameterFilter {
                $Configuration.Filter.Tag.Value -contains 'Unit'
            }
        }
    }
}

# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/Publish-PSModule.ps1
    }

    Context 'when no versioned folder exists' {
        It 'should warn and not publish' {
            $emptyOutput = Join-Path -Path $TestDrive -ChildPath 'empty'
            New-Item -ItemType Directory -Path "$emptyOutput/TestModule" -Force | Out-Null
            Mock Publish-PSResource {}
            Publish-PSModule `
                -Name 'TestModule' `
                -OutputDirectory $emptyOutput `
                -ApiKey 'fake' `
                -WarningVariable warnings `
                -WarningAction SilentlyContinue
            ( $warnings -join ' ' ) | Should -Match 'No module named TestModule found to publish'
            Should -Invoke Publish-PSResource -Times 0
        }
    }

    Context 'when a versioned folder exists' {
        BeforeEach {
            $script:moduleOutput = Join-Path -Path $TestDrive -ChildPath 'out'
            $script:versionedFolder = Join-Path -Path $script:moduleOutput -ChildPath 'TestModule/1.0.0'
            New-Item -ItemType Directory -Path $script:versionedFolder -Force | Out-Null
            New-ModuleManifest `
                -Path (Join-Path -Path $script:versionedFolder -ChildPath 'TestModule.psd1') `
                -ModuleVersion '1.0.0' `
                -Author 'Tester' `
                -Description 'Stub module for tests.'
            Set-Content -Path (Join-Path -Path $script:versionedFolder -ChildPath 'TestModule.psm1') -Value '# empty'

            Mock Publish-PSResource {}
            Mock Find-PSResource {
                [PSCustomObject]@{ Name = 'TestModule'; Version = '1.0.0' }
            }
        }

        It 'should call Publish-PSResource with the versioned folder path' {
            Publish-PSModule -Name 'TestModule' -OutputDirectory $script:moduleOutput -ApiKey 'fake'
            Should -Invoke Publish-PSResource -Times 1 -Exactly -ParameterFilter {
                $Path -eq $script:versionedFolder -and $Repository -eq 'PSGallery'
            }
        }

        It 'should throw after exhausting Find-PSResource retries' {
            Mock Find-PSResource { throw 'not found yet' }
            Mock Start-Sleep {}
            {
                Publish-PSModule `
                    -Name 'TestModule' `
                    -OutputDirectory $script:moduleOutput `
                    -ApiKey 'fake' `
                    -WarningAction SilentlyContinue
            } | Should -Throw
            Should -Invoke Find-PSResource -Times 5 -Exactly
        }
    }
}

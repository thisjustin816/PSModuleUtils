# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Get-PSModulePublishedManifest.ps1
    }

    Context 'when a published version exists' {
        BeforeEach {
            Mock Save-PSResource {
                $manifestDir = Join-Path -Path $Path -ChildPath 'TestModule/1.2.3'
                New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
                New-ModuleManifest -Path (Join-Path -Path $manifestDir -ChildPath 'TestModule.psd1') `
                    -ModuleVersion '1.2.3' -Guid 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -Description 'stub'
            }
        }

        It 'should return the published manifest' {
            $manifest = Get-PSModulePublishedManifest -Name 'TestModule' -Repository 'PSGallery'
            $manifest.Guid | Should -Be 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
        }
    }

    Context 'when no published version exists' {
        BeforeEach {
            Mock Save-PSResource {}
        }

        It 'should return nothing and not throw' {
            { Get-PSModulePublishedManifest -Name 'NoSuchModule' -Repository 'PSGallery' } | Should -Not -Throw
            Get-PSModulePublishedManifest -Name 'NoSuchModule' -Repository 'PSGallery' | Should -BeNullOrEmpty
        }
    }
}

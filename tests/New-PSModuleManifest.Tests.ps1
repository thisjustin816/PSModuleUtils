# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        Import-Module -Name 'JBUtils', 'Metadata' -ErrorAction Stop
        . "$PSScriptRoot/../src/Private/Get-PSModulePublishedManifest.ps1"
        . "$PSScriptRoot/../src/Public/New-PSModuleManifest.ps1"
    }

    Context 'when no manifest exists yet' {
        BeforeEach {
            $script:sourceDir = Join-Path -Path $TestDrive -ChildPath ( New-Guid ).Guid
        }

        It 'should write a manifest with the pre-seeded Prerelease/ReleaseNotes keys' {
            New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -SkipRepositoryLookup

            $manifestPath = Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1'
            $manifestPath | Should -Exist

            $manifest = Import-PowerShellDataFile -Path $manifestPath
            $manifest.RootModule | Should -Be 'TestModule.psm1'
            $manifest.FunctionsToExport | Should -BeNullOrEmpty
            $manifest.PrivateData.PSData.Prerelease | Should -Be ''
            $manifest.PrivateData.PSData.ReleaseNotes | Should -Be ''
        }

        It 'should write an explicit module version' {
            New-PSModuleManifest `
                -Name 'TestModule' `
                -SourceDirectory $script:sourceDir `
                -ModuleVersion '2.3.4' `
                -SkipRepositoryLookup

            $manifestPath = Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1'
            (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion.ToString() |
                Should -Be '2.3.4'
        }

        It 'should write the manifest with consistent line endings (regression: no CRLF tail on an LF body)' {
            New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -SkipRepositoryLookup
            $manifestPath = Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1'

            $bytes = [IO.File]::ReadAllBytes($manifestPath)
            $sawBareLf = $false
            $sawCrlf = $false
            for ($i = 0; $i -lt $bytes.Length; $i++) {
                if ($bytes[$i] -eq 10) {
                    if ($i -gt 0 -and $bytes[$i - 1] -eq 13) { $sawCrlf = $true } else { $sawBareLf = $true }
                }
            }

            $sawBareLf | Should -BeTrue -Because 'ConvertTo-Psd1 joins lines with a bare LF'
            $sawCrlf | Should -BeFalse -Because 'a mixed LF-body/CRLF-tail file trips PSScriptAnalyzer''s line-ending detection'
        }

        It 'should produce a manifest Update-Metadata can patch' {
            New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -SkipRepositoryLookup
            $manifestPath = Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1'

            { Update-Metadata -Path $manifestPath -PropertyName 'PrivateData.PSData.ReleaseNotes' -Value 'notes' -ErrorAction Stop } |
                Should -Not -Throw
            (Import-PowerShellDataFile -Path $manifestPath).PrivateData.PSData.ReleaseNotes | Should -Be 'notes'
        }

        It 'should reuse the GUID of a previously published module' {
            Mock Get-PSModulePublishedManifest { @{ Guid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' } }

            New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir
            $manifestPath = Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1'
            (Import-PowerShellDataFile -Path $manifestPath).Guid | Should -Be 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
        }

        It 'should not write anything with -WhatIf' {
            New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -SkipRepositoryLookup -WhatIf
            Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1' | Should -Not -Exist
        }
    }

    Context 'when a manifest already exists' {
        BeforeEach {
            $script:sourceDir = Join-Path -Path $TestDrive -ChildPath ( New-Guid ).Guid
            New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -SkipRepositoryLookup
        }

        It 'should throw without -Force' {
            { New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -SkipRepositoryLookup } |
                Should -Throw '*already exists*'
        }

        It 'should overwrite with -Force' {
            { New-PSModuleManifest -Name 'TestModule' -SourceDirectory $script:sourceDir -Description 'updated' -SkipRepositoryLookup -Force } |
                Should -Not -Throw
            $manifestPath = Join-Path -Path $script:sourceDir -ChildPath 'TestModule.psd1'
            (Import-PowerShellDataFile -Path $manifestPath).Description | Should -Be 'updated'
        }
    }
}

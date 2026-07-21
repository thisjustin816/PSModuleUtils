# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Unit Tests' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Resolve-PSModuleGitRemote.ps1
        . $PSScriptRoot/../src/Private/Get-PSModuleGitMetadata.ps1
    }

    It 'should return metadata for a path inside a git working tree' {
        $metadata = Get-PSModuleGitMetadata -Path "$PSScriptRoot/.."

        $metadata | Should -Not -BeNullOrEmpty
        $metadata.Author | Should -Not -BeNullOrEmpty
        $metadata.CompanyName | Should -Not -BeNullOrEmpty
        $metadata.ProjectUri | Should -Not -BeNullOrEmpty
        $metadata.ProjectUri | Should -Match '^https?://'
        $metadata.ProjectUri | Should -Not -Match '@'
        $metadata.ProjectUri | Should -Not -Match '\.git$'
    }

    It 'should warn and return nothing for a path outside a git working tree' {
        $outsidePath = Join-Path -Path $TestDrive -ChildPath 'not-a-repo'
        New-Item -ItemType Directory -Path $outsidePath -Force | Out-Null

        $metadata = Get-PSModuleGitMetadata -Path $outsidePath -WarningVariable warnings -WarningAction SilentlyContinue

        $metadata | Should -BeNullOrEmpty
        ( $warnings -join ' ' ) | Should -Match 'not inside a git working tree'
    }

    It 'should warn and leave repository metadata blank when the remote cannot be resolved' {
        Mock Resolve-PSModuleGitRemote { throw 'unsupported remote' }
        $metadataParameters = @{
            Path            = "$PSScriptRoot/.."
            WarningVariable = 'warnings'
            WarningAction   = 'SilentlyContinue'
        }

        $metadata = Get-PSModuleGitMetadata @metadataParameters

        $metadata.Author | Should -Not -BeNullOrEmpty
        $metadata.CompanyName | Should -BeNullOrEmpty
        $metadata.Copyright | Should -BeNullOrEmpty
        $metadata.ProjectUri | Should -BeNullOrEmpty
        ( $warnings -join ' ' ) | Should -Match (
            'company name was not provided.*Git remote URL could not be resolved'
        )
    }
}

# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Integration Tests' -Tag 'Integration' {
    BeforeAll {
        Import-Module -Name 'ModuleBuilder', 'Metadata' -ErrorAction Stop
        . "$PSScriptRoot/../src/Private/Get-PSModuleGitMetadata.ps1"
        . "$PSScriptRoot/../src/Public/Build-PSModule.ps1"
    }

    It 'should build a versioned module' {
        $BuildPSModule = @{
            Name      = 'PSModuleUtils'
            Version   = '1.0.0-pester'
            CopyPaths = 'Settings'
        }

        Build-PSModule @BuildPSModule -SourceDirectory "$PSScriptRoot/../src" -OutputDirectory "$TestDrive/out" -SkipGitMetadata

        # ModuleBuilder strips the prerelease label from the output folder name.
        "$TestDrive/out/PSModuleUtils/1.0.0/PSModuleUtils.psd1" | Should -Exist
        "$TestDrive/out/PSModuleUtils/1.0.0/Settings/PSScriptAnalyzerSettings.psd1" | Should -Exist
        "$TestDrive/out/PSModuleUtils/1.0.0/private" | Should -Not -Exist
        { Import-Module -Name "$TestDrive/out/PSModuleUtils/1.0.0/PSModuleUtils.psd1" -Force } |
            Should -Not -Throw
    }

    It 'should preserve purpose-specific asset directories' {
        $sourceDirectory = Join-Path -Path $TestDrive -ChildPath 'AssetModule/src'
        $assembliesDirectory = Join-Path -Path $sourceDirectory -ChildPath 'Assemblies'
        $schemasDirectory = Join-Path -Path $sourceDirectory -ChildPath 'Schemas'
        $publicDirectory = Join-Path -Path $sourceDirectory -ChildPath 'Public'
        $null = New-Item -ItemType Directory `
            -Path $assembliesDirectory, $schemasDirectory, $publicDirectory `
            -Force
        $binaryFixture = [Byte[]](0, 1, 2, 13, 10, 255)
        Set-Content -Path "$assembliesDirectory/Example.dll" -Value $binaryFixture -AsByteStream
        Set-Content -Path "$schemasDirectory/Example.schema.json" -Value '{}'
        Set-Content -Path "$publicDirectory/Get-Example.ps1" -Value 'function Get-Example { $true }'
        New-ModuleManifest -Path "$sourceDirectory/AssetModule.psd1" `
            -RootModule 'AssetModule.psm1' `
            -ModuleVersion '1.0.0' `
            -FunctionsToExport @()

        Build-PSModule -Name 'AssetModule' `
            -SourceDirectory $sourceDirectory `
            -OutputDirectory "$TestDrive/assets-out" `
            -CopyPaths 'Assemblies', 'Schemas' `
            -SkipGitMetadata

        "$TestDrive/assets-out/AssetModule/1.0.0/Assemblies/Example.dll" | Should -Exist
        "$TestDrive/assets-out/AssetModule/1.0.0/Schemas/Example.schema.json" | Should -Exist
        $copiedBinary = Get-Content `
            -Path "$TestDrive/assets-out/AssetModule/1.0.0/Assemblies/Example.dll" `
            -AsByteStream `
            -Raw
        [Convert]::ToBase64String($copiedBinary) | Should -Be ([Convert]::ToBase64String($binaryFixture))
    }

    It 'should reject noncanonical source directory casing' {
        $sourceDirectory = Join-Path -Path $TestDrive -ChildPath 'CaseModule/src'
        $publicDirectory = Join-Path -Path $sourceDirectory -ChildPath 'public'
        $null = New-Item -ItemType Directory -Path $publicDirectory -Force
        Set-Content -Path "$publicDirectory/Get-Example.ps1" -Value 'function Get-Example { $true }'
        New-ModuleManifest -Path "$sourceDirectory/CaseModule.psd1" `
            -RootModule 'CaseModule.psm1' `
            -ModuleVersion '1.0.0' `
            -FunctionsToExport @()

        {
            Build-PSModule `
                -Name 'CaseModule' `
                -SourceDirectory $sourceDirectory `
                -OutputDirectory "$TestDrive/case-out" `
                -SkipGitMetadata
        } | Should -Throw "*Source directory 'public' must be named 'Public'.*"
    }
}

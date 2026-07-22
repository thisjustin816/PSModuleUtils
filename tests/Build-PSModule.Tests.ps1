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
        Build-PSModule `
            -Version '1.0.0-pester' `
            -SourceDirectory "$PSScriptRoot/../src" `
            -OutputDirectory "$TestDrive/out" `
            -SkipGitMetadata

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
        Set-Content -Path "$sourceDirectory/AssetModule.types.ps1xml" -Value '<Types />'
        Set-Content -Path "$publicDirectory/Get-Example.ps1" -Value 'function Get-Example { $true }'
        New-ModuleManifest -Path "$sourceDirectory/AssetModule.psd1" `
            -RootModule 'AssetModule.psm1' `
            -ModuleVersion '1.0.0' `
            -FunctionsToExport @()

        Build-PSModule -SourceDirectory $sourceDirectory `
            -OutputDirectory "$TestDrive/assets-out" `
            -SkipGitMetadata

        "$TestDrive/assets-out/AssetModule/1.0.0/Assemblies/Example.dll" | Should -Exist
        "$TestDrive/assets-out/AssetModule/1.0.0/Schemas/Example.schema.json" | Should -Exist
        "$TestDrive/assets-out/AssetModule/1.0.0/AssetModule.types.ps1xml" | Should -Exist
        "$TestDrive/assets-out/AssetModule/1.0.0/Public" | Should -Not -Exist
        $copiedBinary = Get-Content `
            -Path "$TestDrive/assets-out/AssetModule/1.0.0/Assemblies/Example.dll" `
            -AsByteStream `
            -Raw
        [Convert]::ToBase64String($copiedBinary) | Should -Be ([Convert]::ToBase64String($binaryFixture))
    }

    It 'should reject ambiguous source manifest discovery' {
        $sourceDirectory = Join-Path -Path $TestDrive -ChildPath 'AmbiguousModule/src'
        $null = New-Item -ItemType Directory -Path $sourceDirectory -Force
        New-ModuleManifest -Path "$sourceDirectory/First.psd1" -RootModule 'First.psm1' -ModuleVersion '1.0.0'
        New-ModuleManifest -Path "$sourceDirectory/Second.psd1" -RootModule 'Second.psm1' -ModuleVersion '1.0.0'

        {
            Build-PSModule `
                -SourceDirectory $sourceDirectory `
                -OutputDirectory "$TestDrive/ambiguous-out" `
                -SkipGitMetadata
        } | Should -Throw "*Expected one module manifest in '$sourceDirectory', but found 2.*"
    }

    It 'should preserve additional explicit copy paths' {
        $sourceDirectory = Join-Path -Path $TestDrive -ChildPath 'ExplicitAssetModule/src'
        $publicDirectory = Join-Path -Path $sourceDirectory -ChildPath 'Public'
        $externalDirectory = Join-Path -Path $TestDrive -ChildPath 'ExternalAssets'
        $null = New-Item -ItemType Directory -Path $publicDirectory, $externalDirectory -Force
        Set-Content -Path "$publicDirectory/Get-Example.ps1" -Value 'function Get-Example { $true }'
        Set-Content -Path "$externalDirectory/NOTICE.txt" -Value 'Additional asset'
        New-ModuleManifest -Path "$sourceDirectory/ExplicitAssetModule.psd1" `
            -RootModule 'ExplicitAssetModule.psm1' `
            -ModuleVersion '1.0.0' `
            -FunctionsToExport @()

        Build-PSModule `
            -SourceDirectory $sourceDirectory `
            -OutputDirectory "$TestDrive/explicit-assets-out" `
            -CopyPaths $externalDirectory `
            -SkipGitMetadata

        "$TestDrive/explicit-assets-out/ExplicitAssetModule/1.0.0/ExternalAssets/NOTICE.txt" | Should -Exist
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

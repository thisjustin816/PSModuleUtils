# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Integration Tests' -Tag 'Integration' {
    BeforeAll {
        Import-Module -Name 'ModuleBuilder', 'Metadata' -ErrorAction Stop
        . "$PSScriptRoot/../src/Private/Get-PSModuleGitMetadata.ps1"
        . "$PSScriptRoot/../src/Public/Build-PSModule.ps1"
    }

    It 'should exclude a not-yet-created output directory from source assets' {
        $sourceDirectory = Join-Path $TestDrive 'OutputAssetModule'
        $null = New-Item -ItemType Directory -Path $sourceDirectory -Force
        New-ModuleManifest -Path (Join-Path $sourceDirectory 'OutputAssetModule.psd1') `
            -RootModule 'OutputAssetModule.psm1' `
            -ModuleVersion '1.0.0'
        $outputDirectory = Join-Path $sourceDirectory 'out'
        Mock Build-Module { throw 'Stopped at the build boundary.' }

        {
            Build-PSModule -SourceDirectory $sourceDirectory `
                -OutputDirectory $outputDirectory `
                -SkipGitMetadata
        } | Should -Throw '*Stopped at the build boundary*'

        Should -Invoke Build-Module -Exactly 1 -ParameterFilter { $CopyPaths -notcontains 'out' }
        $outputDirectory | Should -Not -Exist
    }

    It 'should build and rebuild into the caller-relative output directory' {
        $fixtureRoot = Join-Path $TestDrive 'Relative Output Module'
        $sourceDirectory = Join-Path $fixtureRoot 'src'
        $publicDirectory = Join-Path $sourceDirectory 'Public'
        $null = New-Item -ItemType Directory -Path $publicDirectory -Force
        Set-Content -LiteralPath (Join-Path $publicDirectory 'Get-RelativeExample.ps1') `
            -Value 'function Get-RelativeExample { $true }'
        New-ModuleManifest -Path (Join-Path $sourceDirectory 'RelativeOutputModule.psd1') `
            -RootModule 'RelativeOutputModule.psm1' `
            -ModuleVersion '1.0.0' `
            -FunctionsToExport @()
        $expectedDirectory = Join-Path $fixtureRoot 'build output/RelativeOutputModule/1.0.0'
        $expectedManifest = Join-Path $expectedDirectory 'RelativeOutputModule.psd1'

        Push-Location -LiteralPath $fixtureRoot
        try {
            $firstBuild = Build-PSModule -SourceDirectory $sourceDirectory `
                -OutputDirectory './build output' `
                -SkipGitMetadata

            $firstBuild.FullName | Should -Be $expectedManifest
            $expectedManifest | Should -Exist
            (Join-Path $sourceDirectory 'build output') | Should -Not -Exist

            $staleFile = Join-Path $expectedDirectory 'stale.txt'
            Set-Content -LiteralPath $staleFile -Value 'Stale build output'
            $secondBuild = Build-PSModule -SourceDirectory $sourceDirectory `
                -OutputDirectory './build output' `
                -SkipGitMetadata

            $secondBuild.FullName | Should -Be $expectedManifest
            $expectedManifest | Should -Exist
            $staleFile | Should -Not -Exist
            (Join-Path $sourceDirectory 'build output') | Should -Not -Exist
        }
        finally {
            Remove-Module -Name 'RelativeOutputModule' -Force -ErrorAction SilentlyContinue
            Pop-Location
        }
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

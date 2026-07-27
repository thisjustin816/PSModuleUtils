# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Module Validation' {
    BeforeAll {
        $script:builtManifest = Get-ChildItem -Path "$PSScriptRoot/../out/PSModuleUtils" -Filter 'PSModuleUtils.psd1' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object -Property FullName -Descending |
            Select-Object -First 1
    }

    Context 'built module' {
        It 'should have been built before running this test' {
            $script:builtManifest | Should -Not -BeNullOrEmpty -Because 'Build-PSModule must run before Module Validation tests'
        }

        It 'should not contain Pester test syntax' {
            # Regression guard: ModuleBuilder inlines every .ps1 under its source folders, so a
            # *.Tests.ps1 left inside Public/Private would leak Describe/It blocks into the built module.
            $builtScript = Join-Path -Path $script:builtManifest.DirectoryName -ChildPath 'PSModuleUtils.psm1'
            $builtScript | Should -Not -FileContentMatch '^Describe '
        }

        It 'should produce a publishable package' {
            $package = Compress-PSResource `
                -Path $script:builtManifest.DirectoryName `
                -DestinationPath $TestDrive `
                -PassThru `
                -ErrorAction Stop
            $package.FullName | Should -Exist
        }

        It 'should export exactly its own public functions' {
            Get-Module -Name 'PSModuleUtils' -All | Remove-Module -Force -ErrorAction SilentlyContinue
            $utils = Import-Module -Name $script:builtManifest.FullName -Force -PassThru

            $expected = @(
                Get-ChildItem -Path "$PSScriptRoot/../src/Public" -Filter '*.ps1' -File |
                    ForEach-Object { $_.BaseName } |
                    Sort-Object
            )

            try {
                @($utils.ExportedFunctions.Keys | Sort-Object) | Should -Be $expected
            }
            finally {
                Remove-Module -Name 'PSModuleUtils' -Force -ErrorAction SilentlyContinue
            }
        }

        It 'should not nest the modules it builds inside itself' {
            Get-Module -Name 'PSModuleUtils' -All | Remove-Module -Force -ErrorAction SilentlyContinue
            $utils = Import-Module -Name $script:builtManifest.FullName -Force -PassThru

            $probeRoot = Join-Path $TestDrive 'Nested.Probe'
            $probeSource = Join-Path $probeRoot 'src'
            $null = New-Item -ItemType Directory -Path (Join-Path $probeSource 'Public') -Force
            Set-Content `
                -LiteralPath (Join-Path $probeSource 'Public/Get-Probe.ps1') `
                -Value 'function Get-Probe { 1 }'
            Set-Content -LiteralPath (Join-Path $probeSource 'Nested.Probe.psd1') -Value @'
@{
    RootModule        = 'Nested.Probe.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '4c2f1b60-2f7a-4c58-9f3e-7d1b6a0c5e12'
    FunctionsToExport = @()
}
'@

            # Must go through the module's exported command: build.ps1 dot-sources src/Public, so a
            # bare Build-PSModule call runs at script scope, nests nothing, and passes either way.
            $null = & $utils.ExportedCommands['Build-PSModule'] `
                -Name 'Nested.Probe' `
                -SourceDirectory $probeSource `
                -OutputDirectory (Join-Path $probeRoot 'out') `
                -SkipGitMetadata

            $nestedNames = @($utils.NestedModules | ForEach-Object { $_.Name })

            try {
                $nestedNames | Should -Not -Contain 'Nested.Probe'
            }
            finally {
                Get-Module -Name 'Nested.Probe' -All | Remove-Module -Force -ErrorAction SilentlyContinue
                Remove-Module -Name 'PSModuleUtils' -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

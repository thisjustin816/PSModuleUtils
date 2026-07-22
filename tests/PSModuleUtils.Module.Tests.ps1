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

        It 'should not export any package management functions' {
            Get-Module -Name 'PSModuleUtils' -All | Remove-Module -Force -ErrorAction SilentlyContinue
            $pkgMgmtFunctions = Get-Command -Module (
                'PackageManagement', 'PowerShellGet', 'Microsoft.PowerShell.PSResourceGet'
            )
            Import-Module -Name $script:builtManifest.FullName -Force
            $moduleFunctions = Get-Command -Module 'PSModuleUtils'
            foreach ($function in $pkgMgmtFunctions) {
                foreach ($moduleFunction in $moduleFunctions) {
                    $moduleFunction.Name | Should -Not -Be $function.Name
                }
            }
            Remove-Module -Name 'PSModuleUtils' -Force
        }
    }
}

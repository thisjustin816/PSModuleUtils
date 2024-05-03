Describe 'Module Validation' {
    BeforeAll {
        $Script:module = Get-Item $PSCommandPath.Replace('.Module.Tests.ps1', '.psm1' )
    }

    Context 'module' {
        It 'should not contain functions' {
            $Script:module.FullName | Should -Not -FileContentMatch 'function'
        }

        It 'should not export any package management functions' {
            Remove-Module -Name $Script:module.BaseName -Force -ErrorAction SilentlyContinue
            $pkgMgmtFunctions = Get-Command -Module (
                'PackageManagement', 'PowerShellGet', 'Microsoft.PowerShell.PSResourceGet'
            )
            Import-Module -Name $Script:module.FullName -Force
            $moduleFunctions = Get-Command -Module $Script:module.BaseName
            foreach ($function in $pkgMgmtFunctions) {
                foreach ($moduleFunction in $moduleFunctions) {
                    $moduleFunction.Name | Should -Not -Be $function.Name
                }
            }
            Remove-Module -Name $Script:module.BaseName -Force
        }
    }
}

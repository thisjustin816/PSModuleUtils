Describe 'Pester reporting contract' -Tag 'Integration' {
    BeforeAll {
        $runnerPath = Join-Path $TestDrive 'Run-Fixture.ps1'
        $script:pesterPath = (Get-Module -Name Pester).Path
        $script:functionPath = (Resolve-Path -LiteralPath "$PSScriptRoot/../src/Public/Test-PSModule.ps1").Path
        Set-Content -LiteralPath $runnerPath -Value @'
param ($FixtureRoot, $FunctionPath, $PesterPath)
$ErrorActionPreference = 'Stop'
Import-Module -Name $PesterPath -ErrorAction Stop
. $FunctionPath
Test-PSModule -Name 'Fixture' -TestPath "$FixtureRoot/tests" -SourceDirectory "$FixtureRoot/src" `
    -ResultsDirectory "$FixtureRoot/results" -Exclude "$FixtureRoot/tests/Excluded.Tests.ps1" `
    -Tag 'Unit' -ExcludeTag 'HostIntegration'
'@
    }

    BeforeEach {
        $fixtureRoot = Join-Path $TestDrive ([Guid]::NewGuid().ToString())
        $null = New-Item -ItemType Directory -Path "$fixtureRoot/src/Public", "$fixtureRoot/tests" -Force
        Set-Content -LiteralPath "$fixtureRoot/src/Public/Get-Fixture.ps1" -Value 'function Get-Fixture { 42 }'
        Set-Content -LiteralPath "$fixtureRoot/tests/Fixture.Tests.ps1" -Value @'
BeforeAll { . "$PSScriptRoot/../src/Public/Get-Fixture.ps1" }
Describe 'Included suite' -Tag 'Unit' {
    It 'runs the source command' { Get-Fixture | Should -Be 42 }
}
Describe 'Host suite' -Tag 'Unit', 'HostIntegration' {
    It 'must not run' { throw 'An excluded tag ran.' }
}
Describe 'Other suite' -Tag 'Live' {
    It 'must not run' { throw 'An unselected tag ran.' }
}
'@
        Set-Content -LiteralPath "$fixtureRoot/tests/Excluded.Tests.ps1" -Value @'
Describe 'Excluded suite' -Tag 'Unit' {
    It 'must not run' { throw 'An excluded file ran.' }
}
'@
    }

    It 'discovers selected tests and produces NUnit and JaCoCo reports in a fresh process' {
        $output = & (Join-Path $PSHOME 'pwsh') -NoProfile -NonInteractive -File $runnerPath `
            $fixtureRoot $script:functionPath $script:pesterPath 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join [Environment]::NewLine)

        $results = [Xml](Get-Content -LiteralPath "$fixtureRoot/results/testResults.xml" -Raw)
        $results.'test-results'.total | Should -Be '1'
        $results.'test-results'.failures | Should -Be '0'
        $coverage = [Xml](Get-Content -LiteralPath "$fixtureRoot/results/coverage.xml" -Raw)
        $coverage.report | Should -Not -BeNullOrEmpty
        $coverage.report.package.name | Should -Be 'Public'
        $lines = $coverage.SelectSingleNode('/report/counter[@type="LINE"]')
        [Int]$lines.covered | Should -BeGreaterThan 0
    }

    It 'rejects a run with only <Mode> tests' -TestCases @(
        @{ Mode = 'filtered' }
        @{ Mode = 'skipped' }
    ) {
        param ($Mode)
        $fixture = if ($Mode -eq 'filtered') {
            "Describe 'Other suite' -Tag Live { It 'would pass' { 1 | Should -Be 1 } }"
        }
        else {
            "Describe 'Skipped suite' -Tag Unit { It 'skips' -Skip { 1 | Should -Be 1 } }"
        }
        Set-Content -LiteralPath "$fixtureRoot/tests/Fixture.Tests.ps1" -Value $fixture
        $output = & (Join-Path $PSHOME 'pwsh') -NoProfile -NonInteractive -File $runnerPath `
            $fixtureRoot $script:functionPath $script:pesterPath 2>&1
        $LASTEXITCODE | Should -Not -Be 0 -Because ($output -join [Environment]::NewLine)
    }

    It 'returns a failing process status and writes the failed-test report' {
        Set-Content -LiteralPath "$fixtureRoot/tests/Fixture.Tests.ps1" -Value @'
Describe 'Failed suite' -Tag 'Unit' {
    It 'fails deliberately' { 1 | Should -Be 2 }
}
'@
        $output = & (Join-Path $PSHOME 'pwsh') -NoProfile -NonInteractive -File $runnerPath `
            $fixtureRoot $script:functionPath $script:pesterPath 2>&1
        $LASTEXITCODE | Should -Not -Be 0 -Because ($output -join [Environment]::NewLine)
        $results = [Xml](Get-Content -LiteralPath "$fixtureRoot/results/testResults.xml" -Raw)
        $results.'test-results'.failures | Should -Be '1'
    }
}

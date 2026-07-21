# Pester declares parameters in lowercase (e.g. -name on It).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCorrectCasing', '')]
param ()

Describe 'Export-PSModuleAnalyzerSettings' -Tag 'Unit' {
    BeforeAll {
        . $PSScriptRoot/../src/Private/Get-PSModuleAnalyzerSettingsPath.ps1
        . $PSScriptRoot/../src/Public/Export-PSModuleAnalyzerSettings.ps1
        $script:bundledSettingsPath = (
            Resolve-Path -Path $PSScriptRoot/../src/Settings/PSScriptAnalyzerSettings.psd1
        ).Path
    }

    BeforeEach {
        $script:workingDirectory = Join-Path -Path $TestDrive -ChildPath (New-Guid)
        $null = New-Item -ItemType Directory -Path $script:workingDirectory
        Push-Location -Path $script:workingDirectory
    }

    AfterEach {
        Pop-Location
    }

    It 'should export to the current directory by default without emitting output' {
        $output = @(Export-PSModuleAnalyzerSettings)
        $expectedPath = Join-Path -Path $script:workingDirectory -ChildPath 'PSScriptAnalyzerSettings.psd1'

        $expectedPath | Should -Exist
        $output.Count | Should -Be 0
    }

    It 'should copy the bundled settings verbatim to an explicit path' {
        $destinationPath = Join-Path -Path $script:workingDirectory -ChildPath 'Analyzer.psd1'

        Export-PSModuleAnalyzerSettings -Path $destinationPath

        $sourceBytes = Get-Content -LiteralPath $script:bundledSettingsPath -AsByteStream -Raw
        $destinationBytes = Get-Content -LiteralPath $destinationPath -AsByteStream -Raw
        [Convert]::ToBase64String($destinationBytes) |
            Should -BeExactly ([Convert]::ToBase64String($sourceBytes))
    }

    It 'should require Force before replacing an existing file' {
        $destinationPath = Join-Path -Path $script:workingDirectory -ChildPath 'Analyzer.psd1'
        Set-Content -LiteralPath $destinationPath -Value 'custom settings'

        { Export-PSModuleAnalyzerSettings -Path $destinationPath } |
            Should -Throw '*already exists*'
        Get-Content -LiteralPath $destinationPath -Raw | Should -Match 'custom settings'

        Export-PSModuleAnalyzerSettings -Path $destinationPath -Force
        $sourceBytes = Get-Content -LiteralPath $script:bundledSettingsPath -AsByteStream -Raw
        $destinationBytes = Get-Content -LiteralPath $destinationPath -AsByteStream -Raw
        [Convert]::ToBase64String($destinationBytes) |
            Should -BeExactly ([Convert]::ToBase64String($sourceBytes))
    }

    It 'should return the exported file when PassThru is specified' {
        $destinationPath = Join-Path -Path $script:workingDirectory -ChildPath 'Analyzer.psd1'

        $result = Export-PSModuleAnalyzerSettings -Path $destinationPath -PassThru

        $result | Should -BeOfType ([System.IO.FileInfo])
        $result.FullName | Should -BeExactly $destinationPath
    }

    It 'should honor WhatIf without creating a file' {
        $destinationPath = Join-Path -Path $script:workingDirectory -ChildPath 'Analyzer.psd1'

        Export-PSModuleAnalyzerSettings -Path $destinationPath -WhatIf

        $destinationPath | Should -Not -Exist
    }

    It 'should throw when the destination parent does not exist' {
        $destinationPath = Join-Path -Path $script:workingDirectory -ChildPath 'missing/Analyzer.psd1'

        { Export-PSModuleAnalyzerSettings -Path $destinationPath } |
            Should -Throw '*parent directory*does not exist*'
    }

    It 'should throw when the bundled settings file cannot be resolved' {
        Mock Get-PSModuleAnalyzerSettingsPath {}
        $destinationPath = Join-Path -Path $script:workingDirectory -ChildPath 'Analyzer.psd1'

        { Export-PSModuleAnalyzerSettings -Path $destinationPath } |
            Should -Throw '*bundled PSScriptAnalyzer settings file could not be resolved*'
    }
}

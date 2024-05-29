function Build-PSModule {
    [CmdletBinding()]
    param (
        [String]$Name = 'PSModule',
        [String]$Version = '0.0.1',
        [String]$Description = 'A PowerShell module.',
        [String[]]$Tags = @('PSEdition_Desktop', 'PSEdition_Core', 'Windows'),
        [String]$SourceDirectory = "$PWD/src",
        [String]$OutputDirectory = "$PWD/out",
        [Switch]$FixScriptAnalyzer
    )

    Write-Host -Object 'Building with the following parameters:'
    Write-Host -Object (
        [PSCustomObject]@{
            Name              = $Name
            Version           = $Version
            Description       = $Description
            Tags              = $Tags
            SourceDirectory   = $SourceDirectory
            OutputDirectory   = $OutputDirectory
            FixScriptAnalyzer = $FixScriptAnalyzer
        } | Format-List | Out-String
    )

    Remove-Item -Path $OutputDirectory -Recurse -Force -ErrorAction SilentlyContinue
    $ModuleOutputDirectory = "$OutputDirectory/$Name/$Version"

    $null = New-Item -Path "$ModuleOutputDirectory/$name.psm1" -ItemType File -Force
    $functionNames = @()
    $moduleContent = @()
    Get-ChildItem -Path "$SourceDirectory/public" -Filter '*.ps1' -Exclude '*.Tests.ps1' -File -Recurse |
        ForEach-Object -Process {
            $functionName = $_.BaseName
            Write-Host -Object "Building function $functionName..."

            $functionNames += $functionName
            $functionContent = Get-Content -Path $_.FullName
            $originalFunctionContent = $functionContent

            # Remove any init blocks outside of the function
            $startIndex = (
                $functionContent.IndexOf('<#'),
                $functionContent.IndexOf($functionContent -match "function $functionName")[0]
            ) | Where-Object -FilterScript { $_ -ge 0 } | Sort-Object | Select-Object -First 1
            $functionContent = $functionContent[$startIndex..($functionContent.Length - 1)]
            
            # Format the private function dot sources for the expected folder structure
            if ($functionContent -match 'private') {
                Write-Host ($functionContent -join "`n")
            }
            $functionContent = $functionContent.Replace('../../private', 'private')

            Write-Host -Object (
                Compare-Object -ReferenceObject $functionContent -DifferenceObject $originalFunctionContent |
                    Format-Table |
                    Out-String
            )
            $moduleContent += ''
            $moduleContent += $functionContent
        }

    $moduleContent | Set-Content -Path "$ModuleOutputDirectory/$name.psm1" -Force
    $null = New-Item -Path "$ModuleOutputDirectory/private" -ItemType Directory -Force
    Get-ChildItem -Path "$SourceDirectory/private" -Exclude '*.Tests.ps1' |
        Copy-Item -Destination "$ModuleOutputDirectory/private" -Recurse -Force

    $manifestPath = "$ModuleOutputDirectory/$Name.psd1"
    $repoUrl = ( & git config --get remote.origin.url ).Replace('.git', '')
    $companyName = if ($repoUrl -match 'github') {
        $repoUrl.Split('/')[3]
    }
    else {
        $env:USERDOMAIN
    }
    $existingGuid = Find-Module -Name $Name -Repository PSGallery -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty AdditionalMetadata |
        Select-Object -ExpandProperty GUID
    $guid = if ($existingGuid) {
        $existingGuid
    }
    else {
        ( New-Guid ).Guid
    }
    $requiredModulesStatement = Get-Content -Path "$SourceDirectory\$Name.psm1" |
        Where-Object -FilterScript { $_ -match '#Requires' }
    $requiredModules = (($requiredModulesStatement -split '-Modules ')[1] -split ',').Trim()
    $moduleVersion, $modulePrerelease = $Version -split '-', 2
    $newModuleManifest = @{
        Path = $manifestPath
        Author = ( & git log --format='%aN' | Sort-Object -Unique )
        CompanyName = $companyName
        Copyright = "(c) $( Get-Date -Format yyyy ) $companyName. All rights reserved."
        RootModule = "$Name.psm1"
        ModuleVersion = $moduleVersion
        Guid = $guid
        Description = $Description
        PowerShellVersion = 5.1
        FunctionsToExport = $functionNames
        CompatiblePSEditions = ('Desktop', 'Core')
        Tags = $Tags
        ProjectUri = $repoUrl
        LicenseUri = 'https://opensource.org/licenses/MIT'
        ReleaseNotes = ( git log -1 --pretty=%B )[0]
    }
    if ($requiredModules) {
        $newModuleManifest['RequiredModules'] = $requiredModules
    }
    if ($modulePrerelease) {
        $newModuleManifest['Prerelease'] = $modulePrerelease
    }
    New-ModuleManifest @newModuleManifest
    Get-Item -Path $manifestPath

    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module -Name $manifestPath -Force -PassThru
}

<#
.SYNOPSIS
Builds a PowerShell module formatted like the ones located at github.com/thisjustin816.

.DESCRIPTION
Builds a PowerShell module formatted like the ones located at github.com/thisjustin816.
- Moves all public functions to a single .psm1 file and all private functions to a private folder.
- Removes any init blocks outside of the function.
- Formats the private function dot sources for the expected folder structure.
- Creates a module manifest.

.PARAMETER Name
The name of the module.

.PARAMETER Version
The version of the module.

.PARAMETER Description
The description of the module.

.PARAMETER Guid
The GUID of the module. If not provided it will look for the GUID in the PSGallery, or generate it.

.PARAMETER Tags
The tags for the module.

.PARAMETER LicenseUri
The URL for the repo's license.

.PARAMETER SourceDirectory
The source directory of the module. Should be a nested directory that doesn't contain and build scripts.

.PARAMETER OutputDirectory
The directory to output the .psm1 module and .psd1 manifest.

.PARAMETER FixScriptAnalyzer
Whether to fix the ScriptAnalyzer issues.

.EXAMPLE
$BuildPSModule = @{
    Name        = 'MyModule'
    Version     = '1.0.0'
    Description = 'A PowerShell module.'
    Tags        = ('PSEdition_Desktop', 'PSEdition_Core')
}
Build-PSModule @BuildPSModule

.NOTES
N/A
#>
function Build-PSModule {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '')]
    [CmdletBinding()]
    param (
        [String]$Name = 'PSModule',
        [String]$Version = '0.0.1',
        [String]$Description = 'A PowerShell module.',
        [String]$Guid,
        [String[]]$Tags = @('PSEdition_Desktop', 'PSEdition_Core', 'Windows'),
        [String]$LicenseUri = 'https://opensource.org/licenses/MIT',
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
            LicenseUri        = $LicenseUri
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
            $functionContent = $functionContent -replace '\$PSScriptRoot/\.\./(\.\./)?private', '$PSScriptRoot/private'

            Write-Host -Object (
                Compare-Object -ReferenceObject $functionContent -DifferenceObject $originalFunctionContent |
                    Format-Table |
                    Out-String
            )
            $moduleContent += ''
            $moduleContent += $functionContent
        }

    $srcModuleContent = Get-Content -Path "$SourceDirectory\$Name.psm1" -Raw
    $startIndex = $srcModuleContent.IndexOf('Get-ChildItem')
    $subString = $srcModuleContent.Substring($startIndex)
    $braceIndex = $subString.IndexOf('}')
    $moduleScriptContent = $subString.Substring($braceIndex + 1)
    if ($moduleScriptContent) {
        $moduleContent += $moduleScriptContent
    }

    $moduleContent | Set-Content -Path "$ModuleOutputDirectory/$name.psm1" -Force
    $null = New-Item -Path "$ModuleOutputDirectory/private" -ItemType Directory -Force
    Get-ChildItem -Path "$SourceDirectory/private" -Exclude '*.Tests.ps1' |
        Copy-Item -Destination "$ModuleOutputDirectory/private" -Recurse -Force

    $manifestPath = "$ModuleOutputDirectory/$Name.psd1"
    $repoUrl = ( & git config --get remote.origin.url )
    $companyName = if ($repoUrl -match 'github') {
        $repoUrl.Split('/')[3]
    }
    elseif ($repoUrl -match 'dev\.azure') {
        $repoUrl.Split('/')[3]
    }
    else {
        $env:USERDOMAIN
    }
    $projectUri = $repoUrl.Replace($companyName + '@', '').Replace('.git', '')

    if (-not $Guid) {
        $publishedModuleGuid = Find-Module -Name $Name -Repository PSGallery -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty AdditionalMetadata |
            Select-Object -ExpandProperty GUID
        $Guid = if ($publishedModuleGuid) {
            $publishedModuleGuid
        }
        else {
            ( New-Guid ).Guid
        }
    }

    $requiredModulesStatement = $srcModuleContent.Split("`n") |
        Where-Object -FilterScript { $_ -match '#Requires' }
    $requiredModules = (($requiredModulesStatement -split '-Modules ')[1] -split ',').Trim() |
        ForEach-Object {
            if ($_ -match '@{') {
                Invoke-Expression -Command $_
            }
            else {
                $_
            }
        }
    $moduleVersion, $modulePrerelease = $Version -split '-', 2
    $newModuleManifest = @{
        Path                 = $manifestPath
        Author               = (( & git log --format='%aN' -- . | Sort-Object -Unique ) -join ', ')
        CompanyName          = $companyName
        Copyright            = "(c) $( Get-Date -Format yyyy ) $companyName. All rights reserved."
        RootModule           = "$Name.psm1"
        ModuleVersion        = $moduleVersion
        Guid                 = $guid
        Description          = $Description
        PowerShellVersion    = 5.1
        FunctionsToExport    = $functionNames
        CompatiblePSEditions = ('Desktop', 'Core')
        Tags                 = $Tags
        ProjectUri           = $projectUri
        LicenseUri           = $LicenseUri
        ReleaseNotes         = ( git log -1 --pretty=%B )[0]
    }
    if ($requiredModules) {
        $newModuleManifest['RequiredModules'] = $requiredModules
    }
    if ($modulePrerelease) {
        $newModuleManifest['Prerelease'] = $modulePrerelease
    }
    Write-Host -Object 'Creating module manifest...'
    Write-Host -Object ( $newModuleManifest | Format-List | Out-String )
    New-ModuleManifest @newModuleManifest
    Get-Item -Path $manifestPath

    Get-Module -Name $Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module -Name $manifestPath -Force -PassThru
}
